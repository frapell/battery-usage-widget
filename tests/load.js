// SPDX-FileCopyrightText: 2026 Franco Pellegrini
// SPDX-License-Identifier: GPL-2.0-or-later
//
// Loads a QML-side JS file into a fresh context, the way QML imports it.

const fs = require("fs");
const path = require("path");
const vm = require("vm");

module.exports = function load(name) {
    const file = path.join(__dirname, "..", "package", "contents", "ui", "code", name);
    const context = vm.createContext({});
    vm.runInContext(fs.readFileSync(file, "utf8"), context, { filename: file });
    return context;
};
