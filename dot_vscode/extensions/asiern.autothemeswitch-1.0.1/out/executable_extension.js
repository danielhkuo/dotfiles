"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = void 0;
const vscode = require("vscode");
//Get User config
const userConfig = vscode.workspace.getConfiguration();
let config;
let light, dark;
let darkCustomizations, lightCustomizations;
let lightTime, darkTime;
let themeKey = "workbench.colorTheme";
//Parse string time to object
function parseTime(va) {
    let t = va.split(":");
    return Number(t[0]) + (Number(t[1]) / 60);
}
function updateSettings() {
    config = vscode.workspace.getConfiguration("AutoThemeSwitch");
    //Dark Theme
    dark = config.dark;
    darkCustomizations = config.darkCustomizations;
    //Light Theme
    light = config.light;
    lightCustomizations = config.lightCustomizations;
    //Time
    darkTime = parseTime(config.darkTime); //Start of darkTime
    lightTime = parseTime(config.lightTime); //Start lightTime
}
function applyChanges() {
    let time = new Date();
    const hours = time.getHours() + (time.getMinutes() / 60);
    if (lightTime <= hours && hours < darkTime) {
        //Set Light Theme
        userConfig.update(themeKey, light, true);
        userConfig.update("workbench.colorCustomizations", lightCustomizations, true);
    }
    else {
        //Set Dark Theme
        userConfig.update(themeKey, dark, true);
        userConfig.update("workbench.colorCustomizations", darkCustomizations, true);
    }
}
function activate(context) {
    context.subscriptions.push(vscode.workspace.onDidChangeConfiguration((e) => {
        updateSettings();
        applyChanges();
    }));
    updateSettings();
    applyChanges();
}
exports.activate = activate;
//# sourceMappingURL=extension.js.map