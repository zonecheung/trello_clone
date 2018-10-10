const coffee = require('coffeescript');
const babelJest = require('babel-jest');

module.exports = {
  process: (src, path, ...rest) => {
    // CoffeeScript files can be .coffee, .litcoffee, or .coffee.md
    if (coffee.helpers.isCoffee(path)) {
      return babelJest.process(coffee.compile(src, { bare: true }), path, ...rest);
    }
    if (!/node_modules/.test(path)) {
      return babelJest.process(src, path, ...rest);
    }
    return src;
  }
};
