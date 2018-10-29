<!doctype html>
<html>
<head>
    <title>Forgotten Password by Username</title>
    <meta charset="utf-8">
</head>
<body>
<br>

<?php
include 'vars.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
?>
<form method="post" action="forgotpassword.php">
    <label for="username">Username</label><input id="username" name="username" type="text"/>
    <br/>
    <input type="submit" name="Send Link" value="Send Link"/>
</form>

<?php
exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') die('Unsupported request');

$username = $_POST['username'];

if (!isset($username)) die('Username missing');

$data = array(
    'client_id' => $AUTH0_CLIENT_ID,
    'client_secret' => $AUTH0_CLIENT_SECRET,
    'audience' => $AUTH0_AUDIENCE,
    'grant_type' => 'client_credentials'
);

$options = array(
    'http' => array(
        'header' => "Content-type: application/json",
        'method' => 'POST',
        'content' => json_encode($data)
    )
);

$url = 'https://' . $AUTH0_DOMAIN . '/oauth/token';

$context = stream_context_create($options);
$result_string = file_get_contents($url, false, $context);

if ($result_string === FALSE) die('unable to get access token');

$result = json_decode($result_string, true);

$access_token = $result['access_token'];

if (!isset($access_token)) die('no access token');

#echo '<br/>access_token:' . $access_token;

$options = array(
    'http' => array(
        'header' => ["Content-type: application/json", "Authorization: Bearer ${access_token}" ],
        'method' => 'GET'
    )
);

#$query = urlencode("q=username:$username");
#$query = "q=(username:$username AND identities.connection:\"unique\")";
#$fields='app_metadata.real_email';
$fields='user_id,app_metadata.real_email';

$query = urlencode("(identities.connection:\"$AUTH0_CONNECTION\" AND username:$username)");
$url = "https://$AUTH0_DOMAIN/api/v2/users?search_engine=v3&include_fields=true&fields=$fields&q=$query";

#echo '<br/>url: ' . $url;

$context = stream_context_create($options);
$result_string = file_get_contents($url, false, $context);

if ($result_string === FALSE) die('unable to search');

$result = json_decode($result_string, true);

if (empty($result)) die('no users found');

#print_r($result);

#die();

$first_result = $result[0];

#echo  'first result: '; print_r($first_result);

$email=$first_result['app_metadata']['real_email'];
#$email=$first_result['email'];
$user_id=$first_result['user_id'];
if (!isset($user_id)) die('no user_id');

#echo  '<br/>user_id: ' . $user_id;

$data = array(
    #'client_id' => $AUTH0_CLIENT_ID,
    'user_id' => $user_id,
    #'email' => $email,
    #'connection' => $AUTH0_CONNECTION
);

#$content = json_encode($data);
#echo '<br/> content: ' . $content;

$options = array(
    'http' => array(
        'header' => ["Content-type: application/json", "Authorization: Bearer ${access_token}" ],
        'method' => 'POST',
        'content' => json_encode($data)
    )
);

$url = "https://$AUTH0_DOMAIN/api/v2/tickets/password-change";

$context = stream_context_create($options);
$result_string = file_get_contents($url, false, $context);

$result = json_decode($result_string, true);

$ticket = $result['ticket'];
#echo '<br/>ticket: ' . $ticket;

mail($email, "Chane Password", $ticket);

echo '<br/>done, check your mailbox!';

exit();
