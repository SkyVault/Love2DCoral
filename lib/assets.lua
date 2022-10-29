return function(love)
  local images = {}
  local image_sets = {}

  local function get_image(id)
    -- TODO: Return a demo texture if not found
    return images[id]
  end

  local function load_image(id, path)
    local img = love.graphics.newImage(path)
    images[id] = img
    return img
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
    get_image = get_image,
    load_image = load_image,
    image_set = image_set,
    get_images_from_set = get_images_from_set,
    get_image_set = get_image_set,
  }
end
