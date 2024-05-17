## How to

#### First - Enable custom configurations
1. Open Firefox
2. Type `about:config` in the address bar
3. Enable the following configurations
  * `toolkit.legacyUserProfileCustomizations.stylesheets`
  * `layers.acceleration.force-enabled`
  * `gfx.webrender.all`
  * `gfx.webrender.enabled`
  * `layout.css.backdrop-filter.enabled`
  * `svg.context-properties.content.enabled`

#### Second - Copy the custom css styles to the `chrome/userChrome.css` file in the Profile directory
1. Open Firefox
2. Type `about:support` in the address bar
3. Click the button right next to the `Profile directory`
4. Open the `chrome` folder - create if not exist
5. Open the `userChrome.css` and copy the `hide_top_bar.css` content to it - create the `userChrome.css` file if does not exist
