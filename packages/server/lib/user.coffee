debug   = require("debug")("cypress:server:user")
api     = require("./api")
cache   = require("./cache")
errors  = require("./errors")

module.exports = {
  get: ->
    cache.getUser()

  set: (user) ->
    cache.setUser(user)

  getBaseLoginUrl: ->
    api.getAuthUrls()
    .get('dashboardAuthUrl')

  logInFromCode: (code, redirectUri) ->
    debug("requesting token from code %s and redirect_uri %s", code, redirectUri)
    api.getTokenFromCode(code, redirectUri)
    .then (res) =>
      debug("received token %o for code, requesting /me", res)
      api.getMe(res.access_token)
      .then (meRes) =>
        debug("received /me %o", meRes)
        user = {
          authToken: res.access_token
          refreshToken: res.refresh_token
          name: meRes.name
          email: meRes.email
        }
        @set(user)
        .return(user)
    .catch (err) =>
      debug("error logging in from code: ", err.message)
      throw err

  logOut: ->
    @get().then (user) ->
      authToken = user and user.authToken

      cache.removeUser().then ->
        if authToken
          api.createSignout(authToken)

  ensureAuthToken: ->
    @get().then (user) ->
      ## return authToken if we have one
      if user and at = user.authToken
        return at
      else
        ## else throw the not logged in error
        error = errors.get("NOT_LOGGED_IN")
        ## tag it as api error since the user is only relevant
        ## in regards to the api
        error.isApiError = true
        throw error
}
