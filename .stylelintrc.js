module.exports = {
  extends: [
    'stylelint-config-standard',
    'stylelint-prettier/recommended',
    '@salesforce-ux/stylelint-plugin-slds'
  ],
  rules: {
    'import-notation': null, // Required for LWC @import syntax
    'custom-property-pattern':
      '^([a-z][a-z0-9]*)(--?[a-z0-9]+)*$|^lwc-[a-zA-Z]+$' // Allow SLDS token names
  }
};
