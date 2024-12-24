const bodyParser = require('body-parser');

const app = require('express')();
api.start();
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.post('/apple_process_sign_in_solar2d', async (req, res) => {
  const { code, id_token, user, error } = req?.body ?? {};
  const redirect_page = "https://scotth.tech/apple_pending_page"; // you can change this domain to your own but keep the path the same

  if (error) {
      // Handle any errors that may occur
      return res.redirect(`${redirect_page}?error=${encodeURIComponent(error)}`);
  }

  // If code and id_token are provided, we proceed to handle the response
  if (code && id_token) {
      // Decode the ID token to get user information (e.g., email, name)
      let userInfo = {};
      try {
          const decodedToken = JSON.parse(Buffer.from(id_token.split('.')[1], 'base64').toString());
          const userData = user ? JSON.parse(user) : {};
          userInfo = {
              userId: decodedToken.sub,
              email: decodedToken.email,
              name: userData.name && `${userData?.name?.firstName}*${userData?.name?.lastName}`,
          };
      } catch (err) {
          return res.redirect(`${redirect_page}?error=${encodeURIComponent('Error decoding ID token')}`);
      }

      // Construct the URL with the user information and code appended
      const resultUrl = `${redirect_page}?` +
          `userId=${encodeURIComponent(userInfo.userId)}&` +
          `email=${encodeURIComponent(userInfo.email)}&` +
          `name=${encodeURIComponent(userInfo.name)}&` +
          `code=${encodeURIComponent(code)}&` +
          `id_token=${encodeURIComponent(id_token)}`;

      // Redirect to the page with the appended query parameters
      return res.redirect(resultUrl);
  }

  // If code or id_token are missing
  return res.redirect(`${redirect_page}?error=${encodeURIComponent('Missing code or id_token')}`);
});

const server = app.listen(80, () => {
  console.log(`Your express app is listening on port 80`);
});

module.exports = {
    app,
    server,
};