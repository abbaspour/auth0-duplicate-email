function login(username, password, callback) {

    console.log('entering FE login username: ' + username);

    const request = require('request');
    const jwt = require('jsonwebtoken');

    // ROPG against unique database
    request({
        url: 'https://' + configuration.Domain + '/oauth/token',
        method: 'POST',
        json: {
            grant_type: "http://auth0.com/oauth/grant-type/password-realm",
            realm: configuration.Connection,
            scope: 'openid profile email username',
            client_id: configuration.Client_ID,
            client_secret: configuration.Client_Secret,
            username: username,
            password: password
        },
        headers: {'content-type': 'application/json'}
    }, function (error, response, body) {
        if (error) {
            return callback(error);
        } else {
            if (response.statusCode !== 200) {
                return callback(new Error("error calling backend DB. status: " + JSON.stringify(response)));
            } else {
                const openidProfile = jwt.decode(body.id_token);
                const email_regex = new RegExp("^" + openidProfile.nickname + "\\+");
                openidProfile.email = openidProfile.email.replace(email_regex, '');
                openidProfile.user_id = openidProfile.sub.replace(/^auth0/, /*configuration.Connection*/'FE');
                openidProfile.username = openidProfile.nickname;
                delete openidProfile.sub;
                delete openidProfile.aud;
                delete openidProfile.iss;
                delete openidProfile.exp;
                delete openidProfile.iat;
                delete openidProfile.nickname;
                return callback(null, openidProfile);
            }
        }
    });
}

