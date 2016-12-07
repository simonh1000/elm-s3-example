exports.config = {
    notifications: false,
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: "js/app.js"

      // To use a separate vendor.js bundle, specify two files path
      // http://brunch.io/docs/config#-files-
      // joinTo: {
      //  "js/app.js": /^(web\/static\/js)/,
      //  "js/vendor.js": /^(web\/static\/vendor)|(deps)/
      // }
      //
      // To change the order of concatenation of files, explicitly mention here
      // order: {
      //   before: [
      //     "web/static/vendor/js/jquery-2.1.1.js",
      //     "web/static/vendor/js/bootstrap.min.js"
      //   ]
      // }
    },
    stylesheets: {
      joinTo: "css/app.css",
      order: {
        after: ["web/elm/css/app.css"] // concat app.css last
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/web/static/assets". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(web\/static\/assets)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      "web/static",
      "test/static",
      "web/elm"
    ],


    // Where to compile files to
    public: "priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/web\/static\/vendor/]
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["web/static/js/app"]
    }
  },
  elmBrunch: {
    // Set to path where `elm-make` is located, relative to `elmFolder` (optional)
    // executablePath: '../../node_modules/elm/binwrappers',

    // Set to path where elm-package.json is located, defaults to project root (optional)
    // if your elm files are not in /app then make sure to configure paths.watched in main brunch config
    // elmFolder: 'web/elm',

    // Set to the elm file(s) containing your "main" function
    // `elm make` handles all elm dependencies (required)
    // relative to `elmFolder`
    mainModules: ['web/elm/Main.elm'],

    // Defaults to 'js/' folder in paths.public (optional)
    // outputFolder: 'some/path/',

    // If specified, all mainModules will be compiled to a single file (optional and merged with outputFolder)
    outputFile: 'main.js',

    // optional: add some parameters that are passed to elm-make
    makeParameters : ['--warn']
},
  npm: {
    enabled: true
  }
};
