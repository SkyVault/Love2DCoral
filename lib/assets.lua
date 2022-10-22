return function(love)
  local images = {}

  local function get_image(id)
    -- TODO: Return a demo texture if not found
    return images[id]
  end

  local function load_image(id, path)
    local img = love.graphics.newImage(path)
    images[id] = img
    return img
  end

  return {
    get_image = get_image,
    load_image = load_image,
  }
end
