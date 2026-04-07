# CS 157A Project | S2 Team 2

## Development

### Prerequisites

- JetBrains IntelliJ IDEA
- MySQL Server + Workbench
- Tomcat 10 or above
- JDK 17 or above

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