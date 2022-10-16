local function enum(tbl)
  local result = {}
  for i = 1, #tbl do
    result[tbl[i]] = i
  end
  result.match = function(value)
    return function(mtable)
      if mtable[value] == nil then
        error("Match is not exhaustive, value does not exist in match table.")
      end
      for k, v in pairs(result) do
        if k ~= "match" and k ~= "case" then
          assert(mtable[v] ~= nil, "match table is not exhaustive. missing '".. k .."'")
        end
      end
      if type(mtable[value]) == "function" then
        return mtable[value]()
      end
      return mtable[value]
    end
  end
  result.case = function(value)
    return function(mtable)
      if type(mtable[value]) == "function" then
        return mtable[value]()
      end
      return mtable[value]
    end
  end
  return result
end

return {
  enum = enum,
}
