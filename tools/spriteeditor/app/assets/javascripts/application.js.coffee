#= require jquery
#= require jquery_ujs
#= require_tree .

jQuery ($) ->
  $('#input-file').change (e) ->
    srcCtx = document.getElementById('src-canvas').getContext('2d')
    dstCtx = document.getElementById('dst-canvas').getContext('2d')
    img = new Image
    img.src = URL.createObjectURL(e.target.files[0])

    colorBucket = {}

    img.onload = ->
      srcCtx.drawImage(img, 0, 0)
      srcImageData = srcCtx.getImageData(0, 0, img.width,  img.height)
      dstImageData = dstCtx.getImageData(0, 0, img.width,  img.height)
      outputIndexBuffer  = []
      numColors    = 16

      # create color bucket
      for x in [0..srcImageData.width-1]
        for y in [0..srcImageData.height-1]
          index = (srcImageData.width * y + x) * 4
          r = srcImageData.data[index + 0]
          g = srcImageData.data[index + 1]
          b = srcImageData.data[index + 2]
          a = srcImageData.data[index + 3]

          key = (r << 16) + (g << 8) + (b)
          unless colorBucket[key]?
            colorBucket[key] =
              r: r
              g: g
              b: b
              count: 1
          else
            colorBucket[key].count += 1

      # turn bucket in an array that can be sorted
      colorList = []
      for key, color of colorBucket
        colorList.push color

      colorList = colorList.sort (a, b) ->
        return  1 if a.count < b.count
        return -1 if a.count > b.count
        return 0


      # reduce the palette by finding unique colors
      similar = (color1, color2, tolerance) ->
        tolerance = Math.floor(tolerance * 255 * 255 * 3)
        distance = 0

        distance += Math.pow(color1.r - color2.r, 2)
        distance += Math.pow(color1.g - color2.g, 2)
        distance += Math.pow(color1.b - color2.b, 2)

        return distance <= tolerance

      different = (color, colors, tolerance) ->
        for c in colors
          if similar(color, c, tolerance)
            return false
        return true

      reducedColorList = []
      for color in colorList when reducedColorList.length < numColors
        if different(color, reducedColorList, 0.01)
          reducedColorList.push(color)

      console.log reducedColorList

      # redraw the reduced image
      findNearestColorInListAndReturnIndex = (list, r, g, b) ->
        color = list[0]
        distance = Math.pow(color.r - r, 2) + Math.pow(color.g - g, 2) + Math.pow(color.b - b, 2)
        currentDistance = distance
        currentColor = color
        n = 0
        if list.length > 1
          for i in [1..list.length-1]
            color2 = list[i]
            distance = Math.pow(color2.r - r, 2) + Math.pow(color2.g - g, 2) + Math.pow(color2.b - b, 2)
            if currentDistance > distance
              currentDistance = distance
              currentColor = color2
              n = i
        return n

      for x in [0..srcImageData.width-1]
        for y in [0..srcImageData.height-1]
          index = (srcImageData.width * y + x) * 4

          r = srcImageData.data[index + 0]
          g = srcImageData.data[index + 1]
          b = srcImageData.data[index + 2]
          a = srcImageData.data[index + 3]

          reducedIndex = findNearestColorInListAndReturnIndex(reducedColorList, r, g, b)

          dstImageData.data[index + 0] = reducedColorList[reducedIndex].r
          dstImageData.data[index + 1] = reducedColorList[reducedIndex].g
          dstImageData.data[index + 2] = reducedColorList[reducedIndex].b
          dstImageData.data[index + 3] = a

          outputIndexBuffer[srcImageData.width * y + x] = reducedIndex

      dstCtx.putImageData(dstImageData, 0, 0)
      arrayBuffer = new ArrayBuffer(img.width * img.height / 8 * 4)
      outputBuffer = new Uint8Array(arrayBuffer);

      rows = []
      for y in [0..img.height-1]
        row = []
        row[0] = 0
        row[1] = 0
        row[2] = 0
        row[3] = 0

        # construct 4 bitplanes
        for x in [0..img.width-1]
          value = outputIndexBuffer[img.width * y + x]
          v = []
          v[0] = ((value >> 3) & 0x01) << (8-x-1)
          v[1] = ((value >> 2) & 0x01) << (8-x-1)
          v[2] = ((value >> 1) & 0x01) << (8-x-1)
          v[3] = (value        & 0x01) << (8-x-1)

          row[0] = row[0] | v[0]
          row[1] = row[1] | v[1]
          row[2] = row[2] | v[2]
          row[3] = row[3] | v[3]

        # save them
        rows[y] = [row[0], row[1], row[2], row[3]]

      for y in [0..img.height-1]
        outputBuffer[y*2  ]              = rows[y][3]
        outputBuffer[y*2+1]              = rows[y][2]
        outputBuffer[y*2+img.height*2]   = rows[y][1]
        outputBuffer[y*2+img.height*2+1] = rows[y][0]


      # download blog
      window.BlobBuilder = window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder || window.MSBlobBuilder
      window.URL = window.URL || window.webkitURL
      blob = new Blob([arrayBuffer]);
      blobURL = window.URL.createObjectURL(blob)

      $("a#download").attr('href', blobURL)

      arrayColorBuffer = new ArrayBuffer(reducedColorList.length * 2)
      outputColorBuffer = new Uint8Array(arrayColorBuffer);

      # generate palette
      console.log reducedColorList
      for i in [0..reducedColorList.length-1]
        color = reducedColorList[i]
        nr = Math.floor(color.r / 8)
        ng = Math.floor(color.g / 8)
        nb = Math.floor(color.b / 8)

        console.log "#{nr} #{ng} #{nb}"

        color = nb * 1024 + ng * 32 + nr

        color_low_byte  =  color       & 0xff
        color_high_byte = (color >> 8) & 0xff

        outputColorBuffer[i*2]   = color_low_byte
        outputColorBuffer[i*2+1] = color_high_byte

        console.log("color: #{color} lh: #{color_high_byte} #{color_low_byte}")

      colorBlob = new Blob([arrayColorBuffer]);
      colorBlobURL = window.URL.createObjectURL(colorBlob)

      $("a#download-palette").attr('href', colorBlobURL)
    return
  return