# CS 157A Project | S2 Team 2

## Introduction

Web Augmented Reality Platform (WARP) is a AR-first social platform where users can collaboratively manipulate a shared
virtual environment using persistent virtual "props".

## Development

### Prerequisites

- JetBrains IntelliJ IDEA
- MySQL Server + Workbench
- Tomcat 10 or above
- JDK 17 or above
- Tailscale (for [HTTPS](#i-cant-use-my-cameragps))

### Database setup

Import the schemas in `schemas/` to MySQL through Workbench as a Dump Project Folder (not self-contained files) prior to
running the project.

### Running in `localhost`

1. With the project open in IDEA, click the hamburger menu on the top left, then _Project Structure_.
2. Under _Project Settings/Artifacts_, click on the `+` button > _Web Application: Exploded_ > _From Modules..._ > _OK_.
3. Exit to the main window.
4. Add a new run configuration in the top right of your window.
5. Under _Run/Debug Configurations_, click on the `+` button > scroll down the dropdown menu > _Tomcat Server/Local_.
6. In the right pane, _Server_ tab, _Application server_ > _Configure..._
7. Set the correct path for _Tomcat Home_, leave everything else on default.
8. Click OK and leave everything in the _Run/Debug Configurations_ default as well.
9. Click "Fix" on the error below if you see it, or head to _Deployment_ tab.
10. Add an _artifact..._ with the plus button and select the "war exploded" option.
11. Head to the _Startup/Connection_ tab to add `DB_USER` and `DB_PASSWORD` environmental variables. These are the
    credentials needed to access your MySQL server.
12. Hit OK to finalize everything.
13. You can now host the project by running this configuration.
14. In a new terminal window. Run `tailscale serve 8080`. The output should then include the HTTPS link you can use to
    connect to the website.

### Troubleshooting

#### I can't use my camera/GPS

Ensure that you are using HTTPS, which you can check by the URL; it should begin with `https://`. HTTPS is required to
access your mobile device's motion sensors for XR usage.

#### Camera allowed, but stuck waiting for GPS lock

You may have disabled GPS permissions for your browser app. If you're using an iPhone, you can head to _Privacy &
Security_ > _Location Services_ > Find your browser app > Set to any option besides _Never_. Then, refresh the page to
re-allow all your camera and GPS.

#### Camera feed is stretched

To be fixed in the future.