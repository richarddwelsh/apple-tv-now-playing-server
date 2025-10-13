"""
Applet: Apple TV
Summary: Apple TV \"Now Playing\"
Description: Shows Apple TV \"Now Playing\" on Tidbyt.
Author: tjmehta
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("time.star", "time")
load("schema.star", "schema")

THUMBNAIL_WIDTH = 22

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apple_tv_mac_address",
                name = "Apple TV MAC Address",
                desc = "Check your Apple TV network settings. Ex: a1:b2:c3:d4:e1:f2",
                icon = "networkWired",
            ),
            schema.Text(
                id = "apple_tv_now_playing_api_host",
                name = "Apple TV Now Playing API Host",
                desc = "This widget requires a local server running locally on your network (https://github.com/tjmehta/apple-tv-now-playing-server)",
                icon = "server",
            ),
        ],
    )

def main(config):
    apple_tv_mac_address = config.get("apple_tv_mac_address")
    if not apple_tv_mac_address:
        return render_error("config missing: apple_tv_mac_address is required")

    apple_tv_now_playing_api_host = config.get("apple_tv_now_playing_api_host")
    if not apple_tv_now_playing_api_host:
        return render_error("config missing: apple_tv_now_playing_api_host is required")

    url = get_api_url(apple_tv_now_playing_api_host, "playing")
    params = {"mac": apple_tv_mac_address, "width": str(THUMBNAIL_WIDTH)}
    resp = http.get(url, params = params)
    json = resp.json()

    if not resp.status_code == 200:
        msg = json.get("message", "unknown")
        return render_error("api error (" + str(resp.status_code) + "):" + msg)

    if json.get("device_state") == "DeviceState.Idle" or json.get("title") == "":
        # just render nothing
        return render_idle(config)

    if (json.get("device_state") in ["DeviceState.Paused", "DeviceState.Stopped"]) and (config.get("treat_paused_as_idle") == "True"):
        return render_idle(config)

    if json.get("artist") and "artwork" in json:
        return render_now_playing_full(json)
    else:
        return render_now_playing_half(json)

def get_api_url(host, path):
    return host + "/" + path

def render_now_playing_full(json):
    title = clean_text(json.get("title"))
    artist = clean_text(json.get("artist", ""))
    album = clean_text(json.get("album", ""))
    thumbnail = base64.decode(json.get("artwork").get("bytes")) if json.get("artwork") else ""
    return render.Root(
        render.Column(
            main_align = "space_around",
            cross_align = "center",
            expanded = True,
            children = [
                render.Row(
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Marquee(
                            offset_start = 4,
                            # offset_end = 1,
                            height = 6,
                            width = 64,
                            child = render.Text(
                                color = "#0FFD00",
                                content = title,
                                font = "tb-8",
                            ),
                        ),
                    ],
                ),
                render.Row(
                    main_align = "start",
                    cross_align = "left",
                    expanded = True,
                    children = [
                        render.Column(
                            main_align = "space_around",
                            cross_align = "left",
                            expanded = True,
                            children = [
                                render.Box(
                                    height = THUMBNAIL_WIDTH,
                                    width = THUMBNAIL_WIDTH,
                                    child = render.Image(
                                        src = thumbnail,
                                        height = THUMBNAIL_WIDTH,
                                        width = THUMBNAIL_WIDTH,
                                    ),
                                ),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "left",
                            expanded = True,
                            children = [
                                render.Box(
                                    height = 1,
                                    width = 1,
                                ),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "left",
                            expanded = True,
                            children = [
                                render.Row(
                                    main_align = "start",
                                    cross_align = "left",
                                    expanded = True,
                                    children = [
                                        render.Marquee(
                                            offset_start = 4,
                                            # offset_end = 1,
                                            height = 7,
                                            width = 64 - THUMBNAIL_WIDTH,
                                            child = render.Text(
                                                content = artist,
                                                color = "#FFFFFF",
                                                font = "tb-8",
                                            ),
                                        ),
                                    ],
                                ),
                                render.Row(
                                    main_align = "start",
                                    cross_align = "left",
                                    expanded = True,
                                    children = [
                                        render.Marquee(
                                            offset_start = 4,
                                            # offset_end = 1,
                                            height = 7,
                                            width = 64 - THUMBNAIL_WIDTH,
                                            child = render.Text(
                                                content = album,
                                                color = "#888888",
                                                font = "tb-8",
                                            ),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def render_now_playing_half(json):
    if json.get("artist"):
        show = json.get("artist")
        episode = json.get("title")
    else:
        title = json.get("title")
        show, episode = parse_title(title)

    # Clean text for display
    show = clean_text(show) if show else None
    episode = clean_text(episode) if episode else None

    # Try to split episode into season/ep + title for 3-line display
    season_ep = None
    ep_title = None
    if episode and " - " in episode:
        parts = episode.split(" - ", 1)
        # Check if first part looks like season/episode (S##E## or S# E#)
        if "S" in parts[0] and "E" in parts[0]:
            season_ep = parts[0].strip()
            ep_title = parts[1].strip() if len(parts) > 1 else None

    # If only one line of text, center it and use larger font
    if show and not episode:
        return render.Root(
            render.Row(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Marquee(
                        offset_start = 8,
                        offset_end = 8,
                        align = "center",
                        height = 13,
                        width = 64,
                        child = render.Text(
                            content = show,
                            color = "#0FFD00",
                            font = "6x13",
                        ),
                    ),
                ],
            ),
        )

    # Three lines: show, season/ep, episode title
    if show and season_ep and ep_title:
        return render.Root(
            render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    # Show name - green, medium
                    render.Box(
                        height = 10,
                        child = render.Marquee(
                            offset_start = 6,
                            offset_end = 6,
                            align = "center",
                            height = 9,
                            width = 64,
                            child = render.Text(
                                content = show,
                                color = "#0FFD00",
                                font = "tb-8",
                            ),
                        ),
                    ),
                    # Season/Episode - white
                    render.Box(
                        height = 10,
                        child = render.Marquee(
                            offset_start = 6,
                            offset_end = 6,
                            align = "center",
                            height = 9,
                            width = 64,
                            child = render.Text(
                                content = season_ep,
                                color = "#FFFFFF",
                                font = "tb-8",
                            ),
                        ),
                    ),
                    # Episode title - gray
                    render.Box(
                        height = 10,
                        child = render.Marquee(
                            offset_start = 6,
                            offset_end = 6,
                            align = "center",
                            height = 9,
                            width = 64,
                            child = render.Text(
                                content = ep_title,
                                color = "#AAAAAA",
                                font = "tb-8",
                            ),
                        ),
                    ),
                ],
            ),
        )

    # Two lines: show and episode
    return render.Root(
        render.Column(
            main_align = "space_evenly",
            cross_align = "center",
            expanded = True,
            children = [
                # Show name - larger, green
                render.Box(
                    height = 14,
                    child = render.Marquee(
                        offset_start = 8,
                        offset_end = 8,
                        align = "center",
                        height = 13,
                        width = 64,
                        child = render.Text(
                            content = show,
                            color = "#0FFD00",
                            font = "6x13",
                        ),
                    ),
                ) if show else None,
                # Small spacer
                render.Box(height = 1) if show and episode else None,
                # Episode info - smaller, gray
                render.Box(
                    height = 10,
                    child = render.Marquee(
                        offset_start = 8,
                        offset_end = 8,
                        align = "center",
                        height = 9,
                        width = 64,
                        child = render.Text(
                            content = episode,
                            color = "#AAAAAA",
                            font = "tb-8",
                        ),
                    ),
                ) if episode else None,
            ],
        ),
    )

def parse_title(title):
    """Parse title into show and episode components.

    Returns (show, episode) tuple where episode may contain S/E info and title.
    """
    if not title:
        return None, None

    # Handle pipe-separated content (TV shows, YouTube, etc.)
    if " | " in title:
        parts = title.split(" | ")
        show = parts[0]

        if len(parts) == 1:
            return show, None

        # Check if second part has S#E# pattern followed by dash
        # Pattern: "Show | S1 E1 - Episode Title"
        if len(parts) >= 2:
            second_part = parts[1]
            # Look for "S##E## - " or "S# E# - " pattern
            if (" E" in second_part or "E" in second_part) and " - " in second_part:
                # Split on dash to separate S/E from episode title
                se_parts = second_part.split(" - ", 1)
                season_ep = se_parts[0].strip()  # "S1 E1"
                ep_title = se_parts[1].strip() if len(se_parts) > 1 else ""

                # Combine: "S1 E1 - Episode Title"
                if ep_title:
                    episode = season_ep + " - " + ep_title
                else:
                    episode = season_ep
                return show, episode

        # No special S/E pattern, join remaining parts
        episode = " | ".join(parts[1:])
        return show, episode

    # Handle dash-separated content (YouTube videos, some titles)
    # Pattern: "Creator - Video Title"
    if " - " in title:
        parts = title.split(" - ", 1)
        return parts[0], parts[1] if len(parts) > 1 else None

    # Single title, no clear separation
    return title, None

def clean_text(text):
    """Clean text for better display on Tidbyt."""
    if not text:
        return text

    # Remove leading @ symbols (YouTube channels)
    text = text.lstrip("@")

    # Remove trailing hashtags and cleanup
    if "#" in text:
        # Find last occurrence of pipe or dash before hashtags
        parts = text.split("#")
        text = parts[0].rstrip()

    # Trim whitespace
    text = text.strip()

    # Replace common long phrases with abbreviations for space
    replacements = {
        "Full Episode": "EP",
        "Full Episodes": "EPs",
        "Compilation": "Comp",
        "Educational": "Edu",
        "Learning Video": "Learn",
    }

    for old, new in replacements.items():
        text = text.replace(old, new)

    return text

def render_idle(config):
    # note: for self-hosted apps you cannot render nothing via []
    return render.Root(
        render.Row(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.Marquee(
                    offset_start = 8,
                    offset_end = 8,
                    align = "center",
                    height = 13,
                    width = 64,
                    child = render.Text(
                        content = "Apple TV",
                        color = "#666666",
                        font = "6x13",
                    ),
                ),
            ],
        ),
    )

def render_error(msg):
    return render.Root(
        render.Row(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.Box(
                    child = render.Marquee(
                        height = 13,
                        width = 36,
                        child = render.Text(
                            content = msg,
                            font = "6x13",
                        ),
                    ),
                ),
            ],
        ),
    )
