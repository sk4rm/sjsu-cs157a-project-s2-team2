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
            return t.slice(0, 120) || resp.statusText;
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
        if (!W || !W.commentsUrl || !W.votesUrl) {
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
            li.innerHTML =
                '<span class="soc-meta">#' + c.commenterId + '</span> ' +
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
        var W = window.WARP;
        var vUrl = W.votesUrl + '?objectId=' + encodeURIComponent(objectId);
        var cUrl = W.commentsUrl + '?objectId=' + encodeURIComponent(objectId);
        return Promise.all([
            fetch(vUrl, {credentials: 'same-origin'}).then(function (r) {
                if (!r.ok) return readErr(r).then(function (e) { throw new Error(e); });
                return r.json();
            }),
            fetch(cUrl, {credentials: 'same-origin'}).then(function (r) {
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
        var W = window.WARP;
        var upBtn = document.getElementById('soc-up-btn');
        var downBtn = document.getElementById('soc-down-btn');
        var clearBtn = document.getElementById('soc-clear-btn');
        var postBtn = document.getElementById('soc-post-btn');
        var list = document.getElementById('soc-list');

        function vote(type) {
            fetch(W.votesUrl, {
                method: 'POST',
                credentials: 'same-origin',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body:
                    'objectId=' +
                    encodeURIComponent(objectId) +
                    '&type=' +
                    encodeURIComponent(String(type))
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

        function clearVote() {
            fetch(W.votesUrl + '?objectId=' + encodeURIComponent(objectId), {
                method: 'DELETE',
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
                fetch(W.commentsUrl, {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body:
                        'objectId=' +
                        encodeURIComponent(objectId) +
                        '&text=' +
                        encodeURIComponent(text)
                })
                    .then(function (r) {
                        if (!r.ok) return readErr(r).then(function (t) { throw new Error(t); });
                        return r.json();
                    })
                    .then(function () {
                        if (ta) ta.value = '';
                        return fetch(
                            W.commentsUrl + '?objectId=' + encodeURIComponent(objectId),
                            {credentials: 'same-origin'}
                        ).then(function (r2) {
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
                fetch(W.commentsUrl + '/' + cid, {method: 'DELETE', credentials: 'same-origin'})
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
