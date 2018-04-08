local ui = {}
ui.width, ui.height = term.getSize()
ui.getCenteredPos = function(elementWidth, boxWidth)
  return math.floor(boxWidth/2-elementWidth/2+1)
end

ui.defaultElementTable = {
  isClicked = function(self, mx, my, x, y)
    return mx>=x and my>=y and mx<x+self.w and my<y+self.h
  end,
  toggleClicked = function(self, clicked)
    if not self.clicked and clicked then
      if self.clickedFunction then
        self:clickedFunction()
      end
    elseif self.clicked and not clicked then
      if self.releasedFunction then
        self:releasedFunction()
      end
    end
    self.clicked = clicked
  end
}

ui.newElement = function(elementTab)
  return function(argTable)
    local element = setmetatable(argTable, {__index = setmetatable(elementTab, {__index = ui.defaultElementTable})})
    element.children = {}
    return element
  end
end

ui.new = {
  template = ui.newElement({
    init = function(self)
    end,
    update = function(self, event, var1, var2, var3, x, y)
    end,
    draw = function(self, x, y)
    end
  }),
  text = ui.newElement({
    init = function(self)
      if not self.x then
        self.x = ui.getCenteredPos(#self.text, self.w)
      end
      if not self.y then
        self.y = ui.getCenteredPos(1, self.h)
      end
      if not self.w then self.w = #self.text end
      if not self.h then self.h = 1 end
    end,
    draw = function(self, x, y)
      term.setCursorPos(x, y)
      term.setBackgroundColor(self.color)
      term.setTextColor(self.textColor)
      term.write(self.text)
    end
  }),
  box = ui.newElement({
    draw = function(self, x, y)
      paintutils.drawFilledBox(x, y, x+self.w-1, y+self.h-1, self.color)
    end
  }),
  button = ui.newElement({
    init = function(self)
      if not self.children then self.children = {} end
      self.children.box = ui.new.box({
        x = 1, y = 1, w = self.w, h = self.h, color = self.color,
        priority = 1
      })
      self.children.label = ui.new.text({
        w = self.w, h = self.h, text = self.label, color = self.color, textColor = self.textColor,
        priority = 2
      })
    end,
    draw = function(self)
      if self.clicked then
        self.children.box.color = self.clickedColor
        self.children.label.color = self.clickedColor
      else
        self.children.box.color = self.color
        self.children.label.color = self.color
      end
    end
  }),
  checkbox = ui.newElement({
    w = 1, h = 1,
    ticked = false,
    init = function(self)
      self.children.text = ui.new.text({
        x = 1, y = 1, color = self.color, textColor = self.textColor, text = " "
      })
    end,
    update = function(self, event, var1, var2, var3)
    end,
    toggle = function(self)
      self.ticked = not self.ticked
      if self.ticked then
        self.children.text.text = "x"
      else
        self.children.text.text = " "
      end
    end,
    draw = function(self, x, y)
      if self.clicked then
        self:toggle()
      end
    end
  }),
  textinput = ui.newElement({
    addChar = function(self, char)
      self.children.text.text = self.children.text.text..char
    end,
    removeChar = function(self)
      local oldText = self.children.text.text
      if #oldText>0 then
        self.children.text.text = string.sub(oldText, 1, #oldText-1)
      end
    end,
    init = function(self)
      self.children.text = ui.new.text({
        x = 1, y = 1, text = "", color = self.color, textColor = self.textColor,
        priority = 2
      })
      self.children.box = ui.new.box({
        x = 1, y = 1, w = self.w, h = self.h, color = self.color,
        priority = 1
      })
    end,
    draw = function(self, x, y)
      local color = self.color
      if self.selected then
        color = self.selectedColor
      end
      self.children.box.color = color
      self.children.text.color = color
    end,
    char = function(self, char)
      if self.selected then
        self:addChar(char)
      end
    end,
    key = function(self, key)
      if self.selected then
        local key = keys.getName(key)
        if key == "backspace" then
          self:removeChar()
        elseif key == "enter" then
          self.selected = false
          if self.finishedFunction then
            self.finishedFunction(self.children.text.text)
          end
        end
      end
    end
  }),
  draggable = ui.newElement({
    init = function(self)
      if self.color then
        self.children.box = ui.new.box({
          x = 1, y = 1, w = self.w, h = self.h, color = self.color
        })
      end
    end,
    mouse_click = function(self, button, x, y)
      if self.clicked then
        self.lastClickedX, self.lastClickedY = x, y
      end
    end,
    ondrag = function(self, x, y)
      if self.lastClickedX then
        self.x = self.x + x-self.lastClickedX
        self.y = self.y + y-self.lastClickedY
        self.lastClickedX, self.lastClickedY = x, y
      end
    end
  }),
  window = ui.newElement({
    init = function(self)
      self.children.draggable = ui.new.draggable({
        x = 1, y = 1, w = self.w, h = self.h, color = self.color
      })
    end,
    draw = function(self, x, y)
      self.x, self.y = self.x+self.children.draggable.x, self.y+self.children.draggable.y
      self.children.draggable.x, self.children.draggable.y = 1, 1
    end
  }),
}

ui.runFunctionOnElement = function(element, func, parent)
  if element.x and element.y and parent.x and parent.y then
    func(element, parent, element.x+parent.x-1, element.y+parent.y-1)
  else
    func(element, parent, 1, 1)
  end

  if element.children then
    ui.runElementFunction(element.children, func, element)
  end
end

ui.runElementFunction = function(elements, func, parent)
  local parent = parent or {x=1,y=1}
  local prioritys = {}
  for elementName, element in pairs(elements) do
    if element.priority then
      prioritys[element.priority] = element
    else
      ui.runFunctionOnElement(element, func, parent)
    end
  end

  for elementNum = 1, #prioritys do
    local element = prioritys[elementNum]
    ui.runFunctionOnElement(element, func, parent)
  end
end

ui.draw = function(elements)
  ui.runElementFunction(elements, function(element, parent, x, y)
    if element.draw then
      element:draw(x, y)
    end
  end)
end

ui.update = function(elements, event, var1, var2, var3)
  ui.runElementFunction(elements, function(element, parent, x, y)
    if (event == "mouse_click" or event == "mouse_drag") then
      if element:isClicked(var2, var3, x, y) then
        if element.selected and event == "mouse_drag" and element.ondrag then
          element:ondrag(var2, var3)
        end
        element.selected = true
        element:toggleClicked(true)
      else
        element.selected = false
        element:toggleClicked(false)
      end
    elseif event == "mouse_up" then
      element:toggleClicked(false)
    end
    if element.update then
      element:update(event, var1, var2, var3, x, y)
    end
    if element[event] then
      element[event](element, var1, var2, var3, x, y)
    end
  end)
end

ui.init = function(elements)
  ui.runElementFunction(elements, function(element, parent)
    if element.init then
      element:init()
    end
  end)
end

ui.run = function(elements)
  local buffer = window.create(term.current(), 1, 1, ui.width, ui.height)
  local oldTerminal = term.redirect(buffer)

  local succ, message = pcall(function()
  ui.init(elements)

  while true do
    buffer.setVisible(false)
    term.setBackgroundColor(colors.black)
    term.clear()
    ui.draw(elements)
    buffer.setVisible(true)

    local event, var1, var2, var3 = os.pullEventRaw()
    if event == "terminate" then break end
    ui.update(elements, event, var1, var2, var3)
  end
  end)

  term.redirect(oldTerminal)
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setCursorPos(1, 1)
  if message and message ~= "" then
    term.setTextColor(colors.orange)
    print(message)
  end
end

return ui
