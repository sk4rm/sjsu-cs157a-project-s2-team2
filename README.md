# CS 157A Project | S2 Team 2

## Development

### Prerequisites

- JetBrains IntelliJ IDEA
- MySQL Server
- Tomcat 10 or above
- JDK 17 or above

### Running in `localhost`

1. With the project open in IDEA, add a new run configuration in the top right of your window.
2. Under _Run/Debug Configurations_, click on the plus sign.
3. Scroll down the dropdown menu to add a new _Tomcat Server/Local_ configuration.
4. In the right pane, _Server_ tab, _Application server_ field, click on _Configure..._
5. Set the correct path for _Tomcat Home_, leave everything else on default.
6. Click OK and leave everything in the _Run/Debug Configurations_ default as well.
7. Click "Fix" on the error below if you see it, or head to _Deployment_ tab.
8. Add an _artifact..._ with the plus button and select the "war exploded" option.
9. Hit OK to finalize everything.
10. You can now host the project by running this configuration.