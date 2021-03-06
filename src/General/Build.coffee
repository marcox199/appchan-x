Build =
  spoilerRange: {}
  shortFilename: (filename, isReply) ->
    # FILENAME SHORTENING SCIENCE:
    # OPs have a +10 characters threshold.
    # The file extension is not taken into account.
    threshold = if isReply then 30 else 40
    if filename.length - 4 > threshold
      "#{filename[...threshold - 5]}(...).#{filename[-3..]}"
    else
      filename
  postFromObject: (data, boardID) ->
    o =
      # id
      postID:   data.no
      threadID: data.resto or data.no
      boardID:  boardID
      # info
      name:     data.name
      capcode:  data.capcode
      tripcode: data.trip
      uniqueID: data.id
      email:    if data.email then encodeURI data.email.replace /&quot;/g, '"' else ''
      subject:  data.sub
      flagCode: data.country
      flagName: data.country_name
      date:     data.now
      dateUTC:  data.time
      comment:  data.com
      capcodeReplies: data.capcode_replies
      # thread status
      isSticky: !!data.sticky
      isClosed: !!data.closed
      # file
    if data.ext or data.filedeleted
      o.file =
        name:      data.filename + data.ext
        timestamp: "#{data.tim}#{data.ext}"
        url: if boardID is 'f'
          "//images.4channel.org/#{boardID}/src/#{data.filename}#{data.ext}"
        else
          "//images.4chan.org/#{boardID}/src/#{data.tim}#{data.ext}"
        height:    data.h
        width:     data.w
        MD5:       data.md5
        size:      data.fsize
        turl:      "//thumbs.4chan.org/#{boardID}/thumb/#{data.tim}s.jpg"
        theight:   data.tn_h
        twidth:    data.tn_w
        isSpoiler: !!data.spoiler
        isDeleted: !!data.filedeleted
    Build.post o
  post: (o, isArchived) ->
    ###
    This function contains code from 4chan-JS (https://github.com/4chan/4chan-JS).
    @license: https://github.com/4chan/4chan-JS/blob/master/LICENSE
    ###
    {
      postID, threadID, boardID
      name, capcode, tripcode, uniqueID, email, subject, flagCode, flagName, date, dateUTC
      isSticky, isClosed
      comment, capcodeReplies
      file
    } = o
    isOP = postID is threadID

    staticPath = '//static.4chan.org/image/'

    if email
      emailStart = '<a href="mailto:' + email + '" class="useremail">'
      emailEnd   = '</a>'
    else
      emailStart = ''
      emailEnd   = ''

    subject = "<span class=subject>#{subject or ''}</span>"

    userID =
      if !capcode and uniqueID
        " <span class='posteruid id_#{uniqueID}'>(ID: " +
          "<span class=hand title='Highlight posts by this ID'>#{uniqueID}</span>)</span> "
      else
        ''

    switch capcode
      when 'admin', 'admin_highlight'
        capcodeClass = " capcodeAdmin"
        capcodeStart = " <strong class='capcode hand id_admin'" +
          "title='Highlight posts by the Administrator'>## Admin</strong>"
        capcode      = " <img src='#{staticPath}adminicon.gif' " +
          "alt='This user is the 4chan Administrator.' " +
          "title='This user is the 4chan Administrator.' class=identityIcon>"
      when 'mod'
        capcodeClass = " capcodeMod"
        capcodeStart = " <strong class='capcode hand id_mod' " +
          "title='Highlight posts by Moderators'>## Mod</strong>"
        capcode      = " <img src='#{staticPath}modicon.gif' " +
          "alt='This user is a 4chan Moderator.' " +
          "title='This user is a 4chan Moderator.' class=identityIcon>"
      when 'developer'
        capcodeClass = " capcodeDeveloper"
        capcodeStart = " <strong class='capcode hand id_developer' " +
          "title='Highlight posts by Developers'>## Developer</strong>"
        capcode      = " <img src='#{staticPath}developericon.gif' " +
          "alt='This user is a 4chan Developer.' " +
          "title='This user is a 4chan Developer.' class=identityIcon>"
      else
        capcodeClass = ''
        capcodeStart = ''
        capcode      = ''

    flag = unless flagCode
      ''
    else if boardID is 'pol'
      " <img src='#{staticPath}country/troll/#{flagCode.toLowerCase()}.gif' alt=#{flagCode} title='#{flagName}' class=countryFlag>"
    else
      " <span title='#{flagName}' class='flag flag-#{flagCode.toLowerCase()}'></span>"

    if file?.isDeleted
      fileHTML = if isOP
        "<div class=file id=f#{postID}><div class=fileInfo></div><span class=fileThumb>" +
          "<img src='#{staticPath}filedeleted.gif' alt='File deleted.' class=fileDeletedRes>" +
        "</span></div>"
      else
        "<div class=file id=f#{postID}><span class=fileThumb>" +
          "<img src='#{staticPath}filedeleted-res.gif' alt='File deleted.' class=fileDeletedRes>" +
        "</span></div>"
    else if file
      ext = file.name[-3..]
      if !file.twidth and !file.theight and ext is 'gif' # wtf ?
        file.twidth  = file.width
        file.theight = file.height

      fileSize = $.bytesToString file.size

      fileThumb = file.turl
      if file.isSpoiler
        fileSize = "Spoiler Image, #{fileSize}"
        unless isArchived
          fileThumb = "#{staticPath}spoiler"
          if spoilerRange = Build.spoilerRange[boardID]
            # Randomize the spoiler image.
            fileThumb += "-#{boardID}" + Math.floor 1 + spoilerRange * Math.random()
          fileThumb += '.png'
          file.twidth = file.theight = 100

      imgSrc = if boardID is 'f'
        ''
      else
        "<a class='fileThumb#{if file.isSpoiler then ' imgspoiler' else ''}' href='#{file.url}' target=_blank>" +
          "<img src='#{fileThumb}' alt='#{fileSize}' data-md5=#{file.MD5} style='height: #{file.theight}px; width: #{file.twidth}px;'>" +
        "</a>"

      # Ha ha, filenames!
      # html -> text, translate WebKit's %22s into "s
      a = $.el 'a', innerHTML: file.name
      filename = a.textContent.replace /%22/g, '"'

      # shorten filename, get html
      a.textContent = Build.shortFilename filename
      shortFilename = a.innerHTML

      # get html
      a.textContent = filename
      filename      = a.innerHTML.replace /'/g, '&apos;'

      fileDims = if ext is 'pdf' then 'PDF' else "#{file.width}x#{file.height}"
      fileInfo = "<span class=fileText id=fT#{postID}#{if file.isSpoiler then " title='#{filename}'" else ''}>File: <a href='#{file.url}' target=_blank>#{file.timestamp}</a>" +
        "-(#{fileSize}, #{fileDims}#{
          if file.isSpoiler
            ''
          else
            ", <span title='#{filename}'>#{shortFilename}</span>"
        }" + ")</span>"

      fileHTML = "<div id=f#{postID} class=file><div class=fileInfo>#{fileInfo}</div>#{imgSrc}</div>"
    else
      fileHTML = ''

    tripcode = if tripcode
      " <span class=postertrip>#{tripcode}</span>"
    else
      ''

    sticky = if isSticky
      " <img src=#{staticPath}sticky.gif alt=Sticky title=Sticky class=stickyIcon>"
    else
      ''
    closed = if isClosed
      " <img src=#{staticPath}closed.gif alt=Closed title=Closed class=closedIcon>"
    else
      ''

    container = $.el 'div',
      id: "pc#{postID}"
      className: "postContainer #{if isOP then 'op' else 'reply'}Container"
      innerHTML: <%= grunt.file.read('src/General/html/Build/post.html').replace(/>\s+/g, '>').replace(/\s+</g, '<').replace(/\s+/g, ' ').trim() %>

    for quote in $$ '.quotelink', container
      href = quote.getAttribute 'href'
      continue if href[0] is '/' # Cross-board quote, or board link
      quote.href = "/#{boardID}/res/#{href}" # Fix pathnames

    Build.capcodeReplies {boardID, threadID, root: container, capcodeReplies}

    container

  capcodeReplies: ({boardID, threadID, bq, root, capcodeReplies}) ->
    return unless capcodeReplies

    generateCapcodeReplies = (capcodeType, array) ->
      "<span class=smaller><span class=bold>#{
        switch capcodeType
          when 'admin'
            'Administrator'
          when 'mod'
            'Moderator'
          when 'developer'
            'Developer'
      } Repl#{if array.length > 1 then 'ies' else 'y'}:</span> #{
        array.map (ID) ->
          "<a href='/#{boardID}/res/#{threadID}#p#{ID}' class=quotelink>&gt;&gt;#{ID}</a>"
        .join ' '
      }</span><br>"
    html = []
    for capcodeType, array of capcodeReplies
      html.push generateCapcodeReplies capcodeType, array

    bq or= $ 'blockquote', root
    $.add bq, [
      $.el 'br'
      $.el 'br'
      $.el 'span',
        className: 'capcodeReplies'
        innerHTML: html.join ''
    ]
