function create(user, callback) {

    console.log('entering FE create user: ' + JSON.stringify(user));
    return callback(null);

    // create user in 'BE' database. append 'user.username' to 'user.email'
    // new email <- user.username + 'user.email
    /*
    const tools = require('auth0-extension-tools');

    tools.managementApi.getClient({
        domain: configuration.Domain,
        clientId: configuration.Client_ID,
        clientSecret: configuration.Client_Secret
    })
        .then(client => {
            user.app_metadata = {real_email: user.email};
            user.email = user.username + '+' + user.email;
            user.connection = configuration.Connection;
            delete user.request_language;
            delete user.client_id;
            delete user.tenant;
            client.createUser(user, function (err) {
                console.log('FE create createUser error:' + err);
                return callback(err);
            });
        })
        .catch(err => {
            console.log('FE create catch error:' + err);
            return callback(err);
        });
    */
}

