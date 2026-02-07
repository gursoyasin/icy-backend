const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');

// Public route to get locale JSON
router.get('/locales/:lang', (req, res) => {
    const lang = req.params.lang || 'tr';
    const filePath = path.join(__dirname, '..', 'locales', `${lang}.json`);

    if (fs.existsSync(filePath)) {
        res.sendFile(filePath);
    } else {
        res.status(404).json({ error: "Locale not found" });
    }
});

module.exports = router;
