(function () {
    function notify(msg, isErr) {
        if (typeof showMessage === 'function') {
            showMessage(msg, isErr);
        } else if (typeof showToast === 'function') {
            showToast(msg, isErr);
        }
    }

    function readErr(resp) {
        return resp.text().then(function (t) {
            if (resp.status === 405) {
                return 'POST blocked or wrong URL (got 405). Hard-refresh; ensure you are on the latest deploy.';
            }
            var slice = (t && t.trim()) ? t.trim().slice(0, 200) : '';
            try {
                var j = JSON.parse(t);
                if (j && typeof j.error === 'string') return j.error;
            } catch (ignore) {}
            if (/^<html/i.test(slice)) {
                return 'server returned HTML (status ' + resp.status + ') — check API URL / deploy.';
            }
            return slice || resp.statusText;
        });
    }

    /** Prefer server-rendered body attributes (XR page / cached WARP can't strip these). */
    function getCommentsUrl() {
        var b = document.body;
        var fromBody = b && b.getAttribute('data-warp-comments');
        var w = window.WARP && window.WARP.commentsUrl;
        var s = (fromBody && String(fromBody).trim()) || (w != null ? String(w).trim() : '');
        return s;
    }

    function getVotesUrl() {
        var b = document.body;
        var fromBody = b && b.getAttribute('data-warp-votes');
        var w = window.WARP && window.WARP.votesUrl;
        var s = (fromBody && String(fromBody).trim()) || (w != null ? String(w).trim() : '');
        return s;
    }

    /**
     * Never pass an empty string to fetch(): it resolves to the current page URL (e.g. /world),
     * which is GET-only → Jetty 405 "POST is not supported by this URL".
     */
    function absApiUrl(pathOrAbsolute) {
        var s = pathOrAbsolute == null ? '' : String(pathOrAbsolute).trim();
        if (!s) {
            throw new Error('missing comments/votes API URL — reload the page');
        }
        if (/^https?:\/\//i.test(s)) {
            return s;
        }
        try {
            return new URL(s, window.location.origin).href;
        } catch (e) {
            throw new Error('bad API URL: ' + s);
        }
    }

    function formPost(url, fields) {
        var fd = new URLSearchParams();
        Object.keys(fields).forEach(function (k) {
            fd.append(k, fields[k]);
        });
        return fetch(absApiUrl(url), {
            method: 'POST',
            mode: 'same-origin',
            credentials: 'same-origin',
            body: fd
        });
    }

    function escapeHtml(s) {
        if (s == null || s === '') return '';
        var d = document.createElement('div');
        d.textContent = s;
        return d.innerHTML;
    }

    function renderShell() {
        var el = document.getElementById('inspector-social');
        if (!el) return null;
        var W = window.WARP;
        var cU = getCommentsUrl();
        var vU = getVotesUrl();
        if (!W || !cU || !vU) {
            el.innerHTML = '';
            return null;
        }
        el.innerHTML =
            '<div class="inspector-social-inner">' +
            '<div class="soc-votes">' +
            '<div class="soc-votes-row">' +
            '<strong>votes</strong> ' +
            '<span id="soc-up-label">0</span>↑ <span id="soc-down-label">0</span>↓' +
            '<span id="soc-yours-hint" class="soc-yours-hint" style="display:none"></span>' +
            '</div>' +
            '<div id="soc-vote-controls" class="soc-vote-btns">' +
            '<button type="button" id="soc-up-btn" class="soc-btn" title="upvote">↑</button>' +
            '<button type="button" id="soc-down-btn" class="soc-btn" title="downvote">↓</button>' +
            '<button type="button" id="soc-clear-btn" class="soc-btn" title="clear vote">clear</button>' +
            '</div>' +
            '</div>' +
            '<div class="soc-comments">' +
            '<div class="soc-comments-head">comments</div>' +
            '<ul id="soc-list" class="soc-list"></ul>' +
            '<div id="soc-form-wrap" class="soc-form-wrap">' +
            '<textarea id="soc-text" class="soc-textarea" rows="2" maxlength="255" placeholder="add a comment…"></textarea>' +
            '<button type="button" id="soc-post-btn" class="soc-btn soc-post">post</button>' +
            '</div>' +
            '</div>' +
            '</div>';
        return el;
    }

    function applyVoteUI(data) {
        var upEl = document.getElementById('soc-up-label');
        var downEl = document.getElementById('soc-down-label');
        var hint = document.getElementById('soc-yours-hint');
        var controls = document.getElementById('soc-vote-controls');
        if (!upEl || !data) return;
        upEl.textContent = String(data.up != null ? data.up : 0);
        downEl.textContent = String(data.down != null ? data.down : 0);
        if (data.yours === 1) {
            hint.style.display = 'inline';
            hint.textContent = ' (yours: ↑)';
        } else if (data.yours === -1) {
            hint.style.display = 'inline';
            hint.textContent = ' (yours: ↓)';
        } else {
            hint.style.display = 'none';
            hint.textContent = '';
        }
        var W = window.WARP;
        if (controls) {
            controls.style.display = W && W.userId != null ? 'flex' : 'none';
        }
    }

    function renderComments(list) {
        var ul = document.getElementById('soc-list');
        if (!ul) return;
        ul.innerHTML = '';
        var uid = window.WARP && window.WARP.userId;
        if (!list || list.length === 0) {
            var empty = document.createElement('li');
            empty.className = 'soc-empty';
            empty.textContent = 'no comments yet';
            ul.appendChild(empty);
            return;
        }
        list.forEach(function (c) {
            var li = document.createElement('li');
            li.className = 'soc-item';
            var canDel = uid != null && Number(c.commenterId) === Number(uid);
            // display name comes from user_accounts via SQL join; fall back to
            // the numeric id if the join was skipped (older deploy / migration).
            var who = (c.commenterDisplayName && String(c.commenterDisplayName).trim())
                || ('#' + c.commenterId);
            li.innerHTML =
                '<span class="soc-meta">' + escapeHtml(who) + '</span> ' +
                '<span class="soc-textpart">' + escapeHtml(c.text) + '</span>' +
                (canDel
                    ? '<button type="button" class="soc-del" data-id="' +
                      c.id +
                      '" title="delete">×</button>'
                    : '');
            ul.appendChild(li);
        });
    }

    function setFormVisible(show) {
        var form = document.getElementById('soc-form-wrap');
        if (form) form.style.display = show ? 'block' : 'none';
    }

    function reloadBoth(objectId) {
        var vUrl;
        var cUrl;
        try {
            vUrl = absApiUrl(getVotesUrl()) + '?objectId=' + encodeURIComponent(objectId);
            cUrl = absApiUrl(getCommentsUrl()) + '?objectId=' + encodeURIComponent(objectId);
        } catch (e) {
            notify(String(e.message || e), true);
            return Promise.resolve();
        }
        return Promise.all([
            fetch(vUrl, {mode: 'same-origin', credentials: 'same-origin'}).then(function (r) {
                if (!r.ok) return readErr(r).then(function (e) { throw new Error(e); });
                return r.json();
            }),
            fetch(cUrl, {mode: 'same-origin', credentials: 'same-origin'}).then(function (r) {
                if (!r.ok) return readErr(r).then(function (e) { throw new Error(e); });
                return r.json();
            })
        ])
            .then(function (pair) {
                applyVoteUI(pair[0]);
                renderComments(pair[1]);
            })
            .catch(function (err) {
                notify(String(err.message || err), true);
            });
    }

    function bindSocialEvents(objectId) {
        var upBtn = document.getElementById('soc-up-btn');
        var downBtn = document.getElementById('soc-down-btn');
        var clearBtn = document.getElementById('soc-clear-btn');
        var postBtn = document.getElementById('soc-post-btn');
        var list = document.getElementById('soc-list');

        function vote(type) {
            var req;
            try {
                req = formPost(getVotesUrl(), {objectId: String(objectId), type: String(type)});
            } catch (e) {
                notify(String(e.message || e), true);
                return;
            }
            req
                .then(function (r) {
                    if (!r.ok) return readErr(r).then(function (t) { throw new Error(t); });
                    return r.json();
                })
                .then(applyVoteUI)
                .catch(function (e) {
                    notify(String(e.message || e), true);
                });
        }

        function clearVote() {
            var delUrl;
            try {
                delUrl = absApiUrl(getVotesUrl()) + '?objectId=' + encodeURIComponent(objectId);
            } catch (e) {
                notify(String(e.message || e), true);
                return;
            }
            fetch(delUrl, {
                method: 'DELETE',
                mode: 'same-origin',
                credentials: 'same-origin'
            })
                .then(function (r) {
                    if (!r.ok) return readErr(r).then(function (t) { throw new Error(t); });
                    return r.json();
                })
                .then(applyVoteUI)
                .catch(function (e) {
                    notify(String(e.message || e), true);
                });
        }

        if (upBtn) upBtn.onclick = function () { vote(1); };
        if (downBtn) downBtn.onclick = function () { vote(-1); };
        if (clearBtn) clearBtn.onclick = clearVote;

        if (postBtn) {
            postBtn.onclick = function () {
                var ta = document.getElementById('soc-text');
                var text = ta && ta.value ? ta.value.trim() : '';
                if (!text) {
                    notify('comment text required', true);
                    return;
                }
                var postReq;
                try {
                    postReq = formPost(getCommentsUrl(), {objectId: String(objectId), text: text});
                } catch (e) {
                    notify(String(e.message || e), true);
                    return;
                }
                postReq
                    .then(function (r) {
                        if (!r.ok) return readErr(r).then(function (t) { throw new Error(t); });
                        return r.json();
                    })
                    .then(function () {
                        if (ta) ta.value = '';
                        var listUrl;
                        try {
                            listUrl =
                                absApiUrl(getCommentsUrl()) +
                                '?objectId=' +
                                encodeURIComponent(objectId);
                        } catch (e2) {
                            return Promise.reject(e2);
                        }
                        return fetch(listUrl, {mode: 'same-origin', credentials: 'same-origin'}).then(function (r2) {
                            if (!r2.ok) return readErr(r2).then(function (t) { throw new Error(t); });
                            return r2.json();
                        });
                    })
                    .then(renderComments)
                    .catch(function (e) {
                        notify(String(e.message || e), true);
                    });
            };
        }

        if (list) {
            list.onclick = function (ev) {
                var t = ev.target;
                if (!t.classList.contains('soc-del')) return;
                var cid = t.getAttribute('data-id');
                if (!cid) return;
                var delCommentUrl;
                try {
                    delCommentUrl = absApiUrl(getCommentsUrl()) + '/' + cid;
                } catch (e) {
                    notify(String(e.message || e), true);
                    return;
                }
                fetch(delCommentUrl, {method: 'DELETE', mode: 'same-origin', credentials: 'same-origin'})
                    .then(function (r) {
                        if (r.status === 204) {
                            reloadBoth(objectId);
                            return;
                        }
                        if (!r.ok) return readErr(r).then(function (err) { throw new Error(err); });
                    })
                    .catch(function (e) {
                        notify(String(e.message || e), true);
                    });
            };
        }
    }

    window.loadInspectorSocial = function (objectId) {
        if (objectId == null) return;
        var container = renderShell();
        if (!container) return;
        var W = window.WARP;
        setFormVisible(W && W.userId != null);
        bindSocialEvents(objectId);
        reloadBoth(objectId);
    };

    window.clearInspectorSocial = function () {
        var el = document.getElementById('inspector-social');
        if (el) el.innerHTML = '';
    };
})();
