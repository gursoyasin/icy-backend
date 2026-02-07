const https = require('https');

const data = JSON.stringify({
    email: 'admin@zenith.com',
    password: 'password123'
});

const options = {
    hostname: 'icy-backend-jsju.onrender.com',
    path: '/api/auth/login',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
    }
};

const req = https.request(options, (res) => {
    console.log(`StatusCode: ${res.statusCode}`);
    let body = '';

    res.on('data', (d) => {
        body += d;
    });

    res.on('end', () => {
        try {
            const json = JSON.parse(body);
            console.log('Login Response:');
            if (json.user) {
                console.log('Name:', json.user.name);
                console.log('Email:', json.user.email);
            } else {
                console.log(json);
            }
        } catch (e) {
            console.error(e);
            console.log('Raw body:', body);
        }
    });
});

req.on('error', (error) => {
    console.error(error);
});

req.write(data);
req.end();
