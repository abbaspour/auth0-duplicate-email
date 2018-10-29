function (user, context, callback) {
    console.log('duplicate email merger user: ' + JSON.stringify(user) + ' / context: ' + JSON.stringify(context));
    // 1. prevents direct login to backend db
    // 2. copies meta+user to id_token on ROPG login
    // 3. link frontend & backend database users on first login


    const request = require('request@2.56.0');

    const userApiUrl = auth0.baseUrl + '/users';

    request({
            url: userApiUrl,
            headers: {
                Authorization: 'Bearer ' + auth0.accessToken
            },
            qs: {
                search_engine: 'v3',
                //q: `(identities.connection:\"unique\" AND username:${user.username} AND email:${user.username}+${user.email})`
                q: `(identities.connection:\"unique\" AND username:${user.username})`
            }
        },
        function(err, response, body) {
            if (err) { console.log('cb error: ' + err); return callback(err); }
            if (response.statusCode !== 200) {
                console.log('invalid response: ' + JSON.stringify(response));
                return callback(new Error(body));
            }

            var data = JSON.parse(body);
            // Ignore non-verified users and current user, if present
            data = data.filter(function(u) {
                return /*u.email_verified &&*/ (u.user_id !== user.user_id);
            });

            if (data.length > 1) {
                console.log('data from search: ' + JSON.stringify(data));
                return callback(new Error('[!] Rule: Multiple user profiles already exist - cannot select base profile to link with'));
            }
            if (data.length === 0) {
                console.log('[-] Skipping link rule');
                return callback(null, user, context);
            }

            var originalUser = data[0];
            var provider = user.identities[0].provider;
            var providerUserId = user.identities[0].user_id;

            console.log(`linking ${originalUser.user_id} to ${providerUserId}`);

            request.post({
                url: userApiUrl + '/' + originalUser.user_id + '/identities',
                headers: {
                    Authorization: 'Bearer ' + auth0.accessToken
                },
                json: {
                    provider: provider,
                    user_id: String(providerUserId)
                }
            }, function(err, response, body) {
                if (response.statusCode >= 400) {
                    console.log('post cb error: ' + JSON.stringify(response));
                    return callback(new Error('Error linking account: ' + response.statusMessage));
                }
                context.primaryUser = originalUser.user_id;
                console.log('link successful');
                return callback(null, user, context);
            });
        });
}