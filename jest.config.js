module.exports = {
    transform: {
        "^.+\\.jsx?$": "babel-jest",
    },
    moduleNameMapper: {
        "\\.(css|scss)$": "identity-obj-proxy",
    },
    testEnvironment: "jsdom",
    moduleFileExtensions: ["js", "jsx"],
    setupFilesAfterEnv: ["./src/setupTests.js"],
    coverageReporters: ["lcov", "text"],
}
