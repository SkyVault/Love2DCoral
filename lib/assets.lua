return function(love)
  local images = {}
  local image_sets = {}

  local fonts = {}

  local function add_image(id, img)
    images[id] = img
    return img
  end

  local function get_image(id)
    -- TODO: Return a demo texture if not found
    return images[id]
  end

  local function load_image(id, path)
    return add_image(id, love.graphics.newImage(path))
  end

  local function add_font(id, font)
    fonts[id] = font
    return font
  end

  local function get_font(id)
    return fonts[id]
  end

  local function load_font(id, path)
    return add_font(id, love.graphics.newFont(path))
  end

  local function image_set(set_id, ...)
    local res = {...}
    image_sets[set_id] = res
    return res
  end

  local function get_images_from_set(set_id)
    local res = {}
    local iset = image_sets[set_id]
    if not iset then
      print("Cannot find image set: ", set_id)
      return nil
    end
    for i = 1, #iset do
      res[i] = get_image(iset[i])
    end
    return res
  end

  local function get_image_set(set_id)
    return image_sets[set_id]
  end

  return {
    add_image = add_image,
    get_image = get_image,
    load_image = load_image,

    add_font = add_font,
    get_font = get_font,
    load_font = load_font,

    image_set = image_set,
    get_images_from_set = get_images_from_set,
    get_image_set = get_image_set,
  }
end
