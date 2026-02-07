const fs = require('fs');
const path = require('path');

const locales = {
    tr: require('../locales/tr.json'),
    en: require('../locales/en.json')
};

exports.t = (key, lang = 'tr') => {
    const dict = locales[lang] || locales['tr'];
    return dict[key] || key;
};
