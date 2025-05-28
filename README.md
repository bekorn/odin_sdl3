
### Build

Build & run the build configurator program (only suports Windows)
```
odin run make.odin -file
```

Process the assets before building the program
```
odin run make_assets.odin -file
```

If using VSCode, build & run the project by running the task `Build & Run Debug`(or just `Ctrl+Shift+B`). Otherwise,
```
odin build src/ -out:bin_deb/app.exe -debug
```
