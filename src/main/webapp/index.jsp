<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>WARP – Web AR Platform</title>
    <style>
        :root {
            --bg-soft: #e9dddd;
            --bg-soft-alt: #e4cbdc;
            --accent-rose: #d37f8f;
            --accent-rose-soft: #e6a3af;
            --accent-gold: #e0ae82;
            --text-main: #3f2b32;
            --text-muted: #7c5e66;
            --border-soft: #e4cbdc;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: radial-gradient(circle at top, var(--bg-soft) 0, var(--bg-soft-alt) 55%, var(--bg-soft) 100%);
            color: var(--text-main);
            min-height: 100vh;
            scroll-behavior: smooth;
        }

        header {
            padding: 10px 18px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid rgba(0,0,0,0.04);
            backdrop-filter: blur(12px);
            position: sticky;
            top: 0;
            z-index: 20;
            background: linear-gradient(to right, rgba(255,255,255,0.92), rgba(255,255,255,0.9));
        }

        .logo {
            font-weight: 700;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            font-size: 0.9rem;
            color: var(--text-main);
        }
        .logo span { color: var(--accent-rose); }

        nav { display: flex; align-items: center; gap: 10px; }
        nav a { font-size: 0.84rem; text-decoration: none; color: var(--text-main); opacity: 0.8; }
        nav a:hover { opacity: 1; }

        /* shared button styles */
        .primary-btn,
        .cta-chip.primary {
            padding: 10px 18px;
            border-radius: 999px;
            border: none;
            background: linear-gradient(135deg, var(--accent-rose), var(--accent-rose-soft));
            color: #ffffff;
            font-weight: 600;
            cursor: pointer;
            font-size: 0.9rem;
            box-shadow: 0 8px 18px rgba(196, 120, 136, 0.5);
            transition: transform 0.12s ease-out, box-shadow 0.12s ease-out, opacity 0.12s ease-out;
        }
        .primary-btn:hover,
        .cta-chip.primary:hover {
            transform: translateY(-1px);
            box-shadow: 0 10px 22px rgba(196, 120, 136, 0.6);
        }
        .primary-btn:active,
        .cta-chip.primary:active {
            transform: translateY(0);
            box-shadow: 0 4px 10px rgba(196, 120, 136, 0.4);
        }

        .ghost-btn,
        .pill,
        .cta-chip {
            padding: 8px 16px;
            border-radius: 999px;
            border: 1px solid var(--border-soft);
            background: rgba(255,255,255,0.8);
            font-size: 0.84rem;
            color: var(--text-main);
            cursor: pointer;
            text-decoration: none;
            transition: background-color 0.12s ease-out, border-color 0.12s ease-out, transform 0.12s ease-out;
        }
        .ghost-btn:hover,
        .pill:hover,
        .cta-chip:hover {
            background: #ffffff;
            border-color: var(--accent-rose-soft);
            transform: translateY(-1px);
        }

        /* page shell + hero */
        .page-shell {
            max-width: 1120px;
            margin: 0 auto;
            padding: 18px 20px 80px;
        }

        .hero-shell {
            min-height: 88vh;
            display: grid;
            grid-template-columns: minmax(0, 3.2fr) minmax(0, 2.3fr);
            gap: 32px;
            align-items: center;
            padding-top: 40px;
        }
        @media (max-width: 900px) {
            .hero-shell {
                grid-template-columns: minmax(0, 1fr);
                padding-top: 26px;
            }
        }
        .hero-eyebrow { font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.14em; color: var(--text-muted); margin-bottom: 8px; display: inline-flex; align-items: center; gap: 6px; }
        .hero-dot { width: 8px; height: 8px; border-radius: 999px; background: var(--accent-gold); box-shadow: 0 0 10px rgba(224,174,130,0.9); }
        h1 { font-size: clamp(2.0rem, 4vw, 2.8rem); margin: 0 0 12px; line-height: 1.1; }

        .hero-highlight {
            color: var(--accent-rose);
            font-family: "SF Pro Rounded", "Arial Rounded MT Bold", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            font-weight: 700;
            letter-spacing: 0.03em;
        }
        .hero-sub { font-size: 0.96rem; color: var(--text-muted); max-width: 34rem; }
        .hero-actions { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 18px; align-items: center; }
        .tagline { margin-top: 16px; font-size: 0.8rem; color: var(--text-muted); }
        .scene-card { position: relative; border-radius: 20px; padding: 16px 16px 18px; background: radial-gradient(circle at top left, #ffffff, var(--bg-soft-alt)); box-shadow: 0 20px 40px rgba(0,0,0,0.12); overflow: hidden; border: 1px solid var(--border-soft); }
        .scene-header { display: flex; justify-content: space-between; align-items: center; font-size: 0.8rem; margin-bottom: 8px; color: var(--text-main); }
        .scene-badge { padding: 4px 8px; border-radius: 999px; border: 1px solid rgba(0,0,0,0.04); font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.18em; background: rgba(224,174,130,0.12); color: var(--accent-gold); }
        .scene-orbit { margin-top: 12px; height: 180px; border-radius: 14px; background: radial-gradient(circle, rgba(230,163,175,0.2), transparent 60%); position: relative; overflow: hidden; }
        .orb { position: absolute; border-radius: 999px; border: 1px solid rgba(255,255,255,0.6); background: radial-gradient(circle at 30% 20%, #ffffff, rgba(214,144,159,0.25)); box-shadow: 0 0 30px rgba(214,144,159,0.55); }
        .orb--primary { width: 82px; height: 82px; top: 28%; left: 12%; }
        .orb--secondary { width: 54px; height: 54px; top: 10%; right: 16%; filter: blur(0.2px); }
        .orb--tertiary { width: 38px; height: 38px; bottom: 12%; right: 26%; opacity: 0.85; }
        .ground-ring { position: absolute; bottom: -40px; left: 5%; right: 5%; height: 80px; border-radius: 50%; background: radial-gradient(ellipse at center, rgba(0,0,0,0.08), transparent 70%); }
        .scene-legend { margin-top: 18px; display: flex; flex-direction: column; gap: 10px; }
        .scene-pill { padding: 10px 12px; border-radius: 12px; background: rgba(255,255,255,0.8); border: 1px solid var(--border-soft); }
        .scene-pill span { display: block; font-size: 0.75rem; color: var(--text-muted); margin-top: 4px; line-height: 1.4; }

        .section-shell {
            max-width: 1120px;
            margin: 0 auto;
            padding: 60px 20px 40px;
        }

        .feed-title {
            font-size: clamp(1.6rem, 3vw, 2.2rem);
            margin: 0 0 12px;
            color: var(--text-main);
            line-height: 1.2;
        }

        .feed-subtitle {
            font-size: 1rem;
            color: var(--text-muted);
            margin: 0 0 32px;
            line-height: 1.5;
            max-width: 680px;
        }

        /* staggered story grid - cleaner 2-column layout */
        .story-grid {
            display: grid;
            grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
            gap: 28px;
            align-items: flex-start;
        }
        @media (max-width: 720px) {
            .story-grid {
                grid-template-columns: minmax(0, 1fr);
            }
        }

        .story-card {
            border-radius: 24px;
            background: rgba(255,255,255,0.96);
            border: 1px solid var(--border-soft);
            padding: 28px 24px 30px;
            box-shadow: 0 18px 40px rgba(0,0,0,0.06);
            position: relative;
        }
        .story-card--accent {
            background: radial-gradient(circle at top left, #ffffff, #f8e6e8);
            border-color: rgba(224,174,130,0.6);
            box-shadow: 0 24px 50px rgba(146, 95, 103, 0.18);
        }

        .story-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 999px;
            font-size: 0.7rem;
            border: 1px solid var(--border-soft);
            background: rgba(255,255,255,0.9);
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 0.14em;
        }
        .story-pill-dot {
            width: 6px;
            height: 6px;
            border-radius: 999px;
            background: var(--accent-rose-soft);
        }

        .story-title {
            margin: 14px 0 10px;
            font-size: 1.1rem;
            color: var(--text-main);
            line-height: 1.3;
        }
        .story-body {
            margin: 0;
            font-size: 0.9rem;
            color: var(--text-muted);
            line-height: 1.5;
        }

        /* feature masonry band - cleaner 2-column split */
        .feature-grid {
            display: grid;
            grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
            gap: 28px;
        }
        @media (max-width: 720px) { .feature-grid { grid-template-columns: minmax(0,1fr); } }

        .feature-card {
            border-radius: 24px;
            background: rgba(255,255,255,0.95);
            border: 1px solid var(--border-soft);
            padding: 28px 24px 30px;
            box-shadow: 0 18px 40px rgba(0,0,0,0.06);
        }
        .feature-card h2 { font-size: 1.15rem; margin: 0 0 10px; color: var(--text-main); line-height: 1.3; }
        .feature-card p { margin: 0; font-size: 0.9rem; color: var(--text-muted); line-height: 1.5; }

        .feature-tag {
            display: inline-flex;
            align-items: center;
            padding: 5px 12px;
            border-radius: 999px;
            border: 1px solid var(--border-soft);
            font-size: 0.75rem;
            color: var(--text-muted);
            margin-bottom: 12px;
        }

        /* community / social proof */
        .community-band {
            display: grid;
            grid-template-columns: minmax(0, 2.1fr) minmax(0, 1.6fr);
            gap: 26px;
            align-items: center;
            min-height: 70vh;
        }
        @media (max-width: 900px) {
            .community-band {
                grid-template-columns: minmax(0, 1fr);
                min-height: auto;
            }
        }

        .community-pills {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }
        .community-pill {
            border-radius: 999px;
            padding: 6px 12px;
            font-size: 0.78rem;
            background: rgba(255,255,255,0.9);
            border: 1px solid var(--border-soft);
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .community-dot {
            width: 10px;
            height: 10px;
            border-radius: 999px;
            background: linear-gradient(135deg, var(--accent-rose-soft), var(--accent-rose));
            box-shadow: 0 0 12px rgba(211,127,143,0.7);
        }

        .community-card {
            border-radius: 28px;
            padding: 32px 28px 34px;
            background: radial-gradient(circle at top left, #ffffff, #f7edef);
            border: 1px solid var(--border-soft);
            box-shadow: 0 22px 48px rgba(0,0,0,0.10);
            position: relative;
            overflow: hidden;
        }

        .community-row {
            display: flex;
            gap: 14px;
            margin-bottom: 18px;
            align-items: center;
        }
        .community-row:last-child {
            margin-bottom: 0;
        }

        .community-avatar {
            width: 44px;
            height: 44px;
            border-radius: 999px;
            background: linear-gradient(135deg, #e6a3af, #e4cbdc);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1rem;
            color: #fff;
            font-weight: 600;
            box-shadow: 0 6px 14px rgba(196,120,136,0.6);
            flex-shrink: 0;
        }

        .community-chip {
            padding: 10px 14px;
            border-radius: 12px;
            background: rgba(255,255,255,0.9);
            border: 1px solid var(--border-soft);
            font-size: 0.85rem;
            color: var(--text-muted);
            line-height: 1.4;
        }

        .community-highlight {
            position: absolute;
            inset: auto -40px -70px;
            height: 120px;
            background: radial-gradient(ellipse at top, rgba(224,174,130,0.55), transparent 65%);
            opacity: 0.6;
        }

        /* flow band before registration */
        .flow-band {
            max-width: 1120px;
            margin: 0 auto;
            padding: 50px 20px 50px;
        }
        .flow-strip {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            justify-content: center;
        }
        .flow-chip {
            border-radius: 999px;
            padding: 10px 18px;
            font-size: 0.85rem;
            background: rgba(255,255,255,0.95);
            border: 1px dashed var(--border-soft);
            color: var(--text-muted);
        }

        /* registration destination at the bottom */
        .signup-panel {
            max-width: 760px;
            margin: 60px auto 56px;
            padding: 32px 28px 34px;
            border-radius: 28px;
            background: radial-gradient(circle at top left, #ffffff, #f7e7e7);
            border: 1px solid var(--border-soft);
            box-shadow: 0 28px 70px rgba(0,0,0,0.12);
        }

        .signup-heading {
            text-align: center;
            margin-bottom: 18px;
        }

        .signup-heading h2 {
            margin: 0 0 6px;
            font-size: 1.4rem;
            color: var(--text-main);
        }

        .signup-subtitle {
            margin: 0;
            font-size: 0.9rem;
            color: var(--text-muted);
        }

        .signup-grid {
            display: grid;
            grid-template-columns: minmax(0, 1.6fr) minmax(0, 1.4fr);
            gap: 24px;
            margin-top: 10px;
        }
        @media (max-width: 900px) {
            .signup-grid {
                grid-template-columns: minmax(0, 1fr);
            }
        }

        .signup-form label {
            display: block;
            margin-top: 10px;
            font-size: 0.9rem;
        }

        .signup-form input {
            width: 100%;
            padding: 9px 11px;
            margin-top: 4px;
            border-radius: 999px;
            border: 1px solid var(--border-soft);
            background: #fdfbfb;
            color: var(--text-main);
        }

        .signup-hint {
            margin-top: 6px;
            font-size: 0.78rem;
            color: var(--text-muted);
        }

        .signup-error {
            padding: 12px;
            margin-bottom: 16px;
            border-radius: 12px;
            background: rgba(211,127,143,0.1);
            border: 1px solid var(--accent-rose-soft);
            color: #a1354b;
            font-size: 0.9rem;
        }

        .signup-button-full {
            width: 100%;
            margin-top: 18px;
        }

        .link-soft {
            color: var(--accent-rose);
            text-decoration: none;
        }

        footer { max-width: 1080px; margin: 0 auto 32px; padding: 0 20px; font-size: 0.75rem; color: var(--text-muted); display: flex; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
    </style>
</head>
<body>
<%
    Long userId = (Long) session.getAttribute("userId");
    String userDisplayName = (String) session.getAttribute("userDisplayName");
    String userRole = (String) session.getAttribute("userRole");
%>
<header>
    <div class="logo">W<span>ARP</span> Studio</div>
    <nav>
        <a href="javascript:void(0)" class="pill" onclick="scrollToTarget('how')">How it works</a>
        <a href="javascript:void(0)" class="pill" onclick="scrollToTarget('usecases')">Use cases</a>
        <a href="javascript:void(0)" class="pill" onclick="scrollToTarget('community')">Community</a>
        <% if (userId == null) { %>
        <a href="<%= request.getContextPath() %>/login">Log in</a>
        <a href="javascript:void(0)" class="primary-btn" onclick="scrollToTarget('join')">Get started</a>
        <% } else { %>
        <span class="pill">Signed in as <strong><%= userDisplayName %></strong><% if (userRole != null) { %> · <%= userRole %><% } %></span>
        <a href="<%= request.getContextPath() %>/account">Account</a>
        <form style="display:inline;margin-left:8px;" method="post" action="<%= request.getContextPath() %>/logout">
            <button type="submit" class="ghost-btn">Sign out</button>
        </form>
        <% } %>
    </nav>
</header>

<div class="page-shell">
    <!-- Tall, airy hero -->
    <section class="hero-shell">
        <div>
        <div class="hero-eyebrow"><span class="hero-dot"></span> CS 157A · Social AR Platform</div>
            <h1>Create <span class="hero-highlight">interactive environments</span> with the people around you.</h1>
        <p class="hero-sub">
                WARP lets you pin moments to the places you already hang out: study spots, club corners, campus paths, and pop-ups that only unlock when you’re there.
        </p>
        <div class="hero-actions">
                <button type="button" class="primary-btn" onclick="scrollToTarget('how')">
                    Start scrolling the world
                </button>
                <button type="button" class="ghost-btn" onclick="scrollToTarget('join')">
                    Jump to sign up ↓
                </button>
            </div>
            <p class="tagline">No app store download, no headsets. Just your browser and the spaces you already move through.</p>
        </div>

    <aside>
        <div class="scene-card">
            <div class="scene-header">
                <span>See the world as a canvas</span>
                    <span class="scene-badge">Live AR layer</span>
            </div>
            <div class="scene-orbit">
                <div class="orb orb--primary"></div>
                <div class="orb orb--secondary"></div>
                <div class="orb orb--tertiary"></div>
                <div class="ground-ring"></div>
            </div>
            <div class="scene-legend">
                <div class="scene-pill">
                    Study trails
                    <span>Leave floating tips around campus.</span>
                </div>
                <div class="scene-pill">
                    Club spaces
                    <span>Pin meetups to real hangout spots.</span>
                </div>
                <div class="scene-pill">
                    Pop-up worlds
                    <span>Stage AR moments for events and brands.</span>
                </div>
            </div>
        </div>
    </aside>
    </section>

    <!-- Long staggered story section -->
<section class="section-shell" id="how">
        <h2 class="feed-title">Your social layer on top of real life</h2>
        <p class="feed-subtitle">As you move around, WARP reveals little scenes from your friends, clubs, and campus: signposts, 3D drops, and prompts waiting in the spots you pass every day.</p>

        <div class="story-grid">
            <article class="story-card story-card--accent">
                <div class="story-pill"><span class="story-pill-dot"></span> Create environments</div>
                <h3 class="story-title">Set the vibe for a place</h3>
                <p class="story-body">
                    Drop signposts, prompts, and objects so your space feels different when people walk through it. Turn a hallway into a welcome path, a quad into a challenge loop, or a shortcut into a secret trail for your friends.
                </p>
            </article>

            <article class="story-card">
                <div class="story-pill"><span class="story-pill-dot"></span> Drop signposts</div>
                <h3 class="story-title">Leave signposts for your people</h3>
                <p class="story-body">
                    Attach notes, clues, and check-ins to real spots so the right thing pops up at the right time. Instead of scrolling a feed, you open WARP and see what’s hidden around you from friends, clubs, and events.
                </p>
            </article>

            <article class="story-card">
                <div class="story-pill"><span class="story-pill-dot"></span> 3D props</div>
                <h3 class="story-title">Scatter 3D stuff in the air</h3>
                <p class="story-body">
                    Float playful 3D models above tables, by stairwells, or next to doors. Use them as markers, surprises, or little props that turn a normal route into something your friends want to walk through.
                </p>
            </article>

            <article class="story-card">
                <div class="story-pill"><span class="story-pill-dot"></span> Community reactions</div>
                <h3 class="story-title">Let friends react in the same spot</h3>
                <p class="story-body">
                    Reactions and remixes stay tied to the place where they happened, so every corner slowly collects its own in-jokes, memories, and updates instead of getting buried in a timeline.
                </p>
            </article>
        </div>
    </section>

    <!-- Masonry-like feature band -->
    <section class="section-shell" id="usecases">
        <h2 class="feed-title">For clubs, friends, events, and anyone with a spot</h2>
        <p class="feed-subtitle">Use WARP as a lightweight social layer for the spaces you already share. No new app ecosystem, no giant setup, just links and places.</p>

    <div class="feature-grid">
        <article class="feature-card">
                <div class="feature-tag">Campus &amp; clubs</div>
                <h2>Guide members through your world</h2>
                <p>Turn hallways into trails, put intros by your door, and leave “you’re in the right place” check-ins around campus. Perfect for clubs and orgs that want a tiny layer on top of everything they already do.</p>
        </article>
        <article class="feature-card">
                <div class="feature-tag">Events &amp; experiences</div>
                <h2>Make events feel discoverable</h2>
                <p>Drop checkpoints, secret prompts, and 3D moments that unlock as people move through your venue. Great for hackathons, showcases, pop-ups, and any night where you want people to wander.</p>
        </article>
        <article class="feature-card">
                <div class="feature-tag">Study &amp; creators</div>
                <h2>Turn study spots into shared notes</h2>
                <p>Anchor flashcards, quick explanations, or last-minute reminders to the places you actually cram. Or leave small AR scenes at cafés and galleries so people can literally walk into your work.</p>
        </article>
        <article class="feature-card">
                <div class="feature-tag">Brands &amp; moderation</div>
                <h2>Add a soft layer for your brand</h2>
                <p>Experiment with tiny AR drops and routes without committing to a full app. Simple tools and basic moderation keep everything feeling friendly and low-friction.</p>
        </article>
    </div>
</section>

    <!-- Community / social proof band -->
    <section class="section-shell" id="community">
        <div class="community-band">
            <div>
                <h2 class="feed-title">Your people, on top of your places</h2>
                <p class="feed-subtitle">
                    WARP is where clubs, events, friends, and nearby creators stack their ideas on top of the same hallways, streets, and hangout spots you already use.
                </p>
                <div class="community-pills">
                    <span class="community-pill"><span class="community-dot"></span> Nearby club scenes</span>
                    <span class="community-pill"><span class="community-dot"></span> Friends’ study trails</span>
                    <span class="community-pill"><span class="community-dot"></span> Event checkpoints</span>
                    <span class="community-pill"><span class="community-dot"></span> Creator drops</span>
                    <span class="community-pill"><span class="community-dot"></span> Brand layers</span>
                </div>
            </div>

            <aside>
                <div class="community-card">
                    <div class="community-row">
                        <div class="community-avatar">C</div>
                        <div class="community-chip">Design club · "Portfolio walk" trail across campus</div>
                    </div>
                    <div class="community-row">
                        <div class="community-avatar">E</div>
                        <div class="community-chip">CS event · "Hackathon check-in" signposts at key locations</div>
                    </div>
                    <div class="community-row">
                        <div class="community-avatar">S</div>
                        <div class="community-chip">Study group · "Night-before review" layer in the library</div>
                    </div>
                    <div class="community-highlight"></div>
                </div>
            </aside>
        </div>
    </section>

    <!-- Flow strip into registration -->
    <section class="flow-band">
        <p class="feed-subtitle" style="text-align:center;margin-bottom:14px;">How WARP feels when you start playing with it</p>
        <div class="flow-strip">
            <span class="flow-chip">Look around your space</span>
            <span class="flow-chip">See what's nearby</span>
            <span class="flow-chip">Drop your first signpost</span>
            <span class="flow-chip">Upload 3D objects</span>
            <span class="flow-chip">Link scenes into trails</span>
            <span class="flow-chip">Grow a shared AR layer</span>
    </div>
</section>

    <!-- Registration destination: full form at bottom -->
<section class="signup-panel" id="join">
        <div class="signup-heading">
            <h2>Make your first WARP space</h2>
            <p class="signup-subtitle">Grab a free account, set your height for AR, and start layering little moments onto the spots you and your friends already pass by.</p>
        </div>

    <% if (userId == null) { %>
        <div class="signup-grid">
            <div>
                <p class="signup-hint">
                    With an account you can:
                </p>
                <ul class="signup-hint" style="padding-left:18px;margin-top:4px;">
                    <li>Create and edit interactive environments.</li>
                    <li>Drop signposts and 3D props into real places.</li>
                    <li>Save favorites and see what friends and clubs leave nearby.</li>
                </ul>
                <p class="signup-hint">
                    Use a real email so you can log back in. Height helps WARP scale scenes to your perspective.
                </p>
            </div>

            <div>
                <%
                    String registerError = (String) session.getAttribute("registerError");
                    if (registerError != null) {
                        session.removeAttribute("registerError");
                %>
                <div class="signup-error">
                    <%= registerError %>
                </div>
                <% } %>
                <form class="signup-form" method="post" action="<%= request.getContextPath() %>/register">
                    <label for="displayNameLanding">Display name</label>
                    <input type="text" id="displayNameLanding" name="displayName" maxlength="64" required>

                    <label for="emailLanding">Email</label>
                    <input type="email" id="emailLanding" name="email" maxlength="256" required>

                    <label for="passwordLanding">Password</label>
                    <input type="password" id="passwordLanding" name="password" minlength="8" required>

                    <label for="confirmPasswordLanding">Confirm password</label>
                    <input type="password" id="confirmPasswordLanding" name="confirmPassword" minlength="8" required>

                    <label for="heightMetersLanding">Height (meters)</label>
                    <input type="number" step="0.01" min="0.5" max="2.5" id="heightMetersLanding" name="heightMeters" required>

        <button type="submit" class="primary-btn signup-button-full">Create a free account</button>
    </form>
                <p class="signup-hint" style="margin-top:10px;">Already have an account?
                    <a href="<%= request.getContextPath() %>/login" class="link-soft">Log in</a>.
                </p>
            </div>
        </div>
    <% } else { %>
        <div class="hero-actions" style="justify-content:center; margin-top: 8px;">
        <form method="get" action="<%= request.getContextPath() %>/account">
                <button type="submit" class="primary-btn">Open my WARP profile</button>
        </form>
        <button type="button" class="ghost-btn" style="margin-left:8px;" onclick="window.scrollTo({ top: 0, behavior: 'smooth' });">Back to top</button>
    </div>
    <% } %>
</section>
    </div>

<footer>
    <span>WARP · CS 157A project</span>
    <span>Made for shared AR spaces · CS 157A</span>
</footer>

<script>
    // simple helper so scroll targets don't end up under the sticky header
    function scrollToTarget(id) {
        var el = document.getElementById(id);
        if (!el) return;

        var headerOffset = 80; // height of sticky header area
        var rect = el.getBoundingClientRect();
        var scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        var targetY = rect.top + scrollTop - headerOffset;

        window.scrollTo({
            top: targetY,
            behavior: 'smooth'
        });
    }
</script>

</body>
</html>
