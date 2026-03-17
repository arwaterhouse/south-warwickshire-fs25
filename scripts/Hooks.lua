-- Author:mleithner
-- Name:Hooks
-- Namespace: global
-- Description:
-- Icon:
-- Hide: yes
-- AlwaysLoaded: yes

HookType = {}
HookType.ON_FILE_OPEN = 0
HookType.ON_FILE_IMPORTED = 1
HookType.ON_SAVE = 2
HookType.ON_SELECTION_CHANGED = 3
HookType.ON_NODE_CLONED = 4
HookType.ON_NODE_DELETED = 5

local listeners = {}  -- mapping from hookType to array of listeners

---
-- @param integer hookType one of HookType.*
-- @param function func
-- @param table? target
-- @return table referenceObject
function addEventListener(hookType, func, target)
    listeners[hookType] = listeners[hookType] or {}

    local listener = {callbackFunc = func, callbackTarget=target}
    table.insert(listeners[hookType], listener)

    return listener  -- return listener table to be used as handle for removal
end

---
-- @param integer hookType one of HookType.*
-- @param table referenceObject returned by subscribeHook()
-- @return boolean success
function removeEventListener(hookType, referenceObject)
    if listeners[hookType] == nil then
        printError(string.format("No listeners for hook type %d", hookType))
        return false
    end

    local index = table.find(listeners[hookType], referenceObject)
    if index == nil then
        printError(string.format("No listener for given reference for hook type %d", hookType))
        return false
    end

    table.remove(listeners[hookType], index)

    return true
end

---
-- @param integer hookType one of HookType.*
-- @param any ... args
function _publish(hookType, ...)
    if listeners[hookType] == nil then
        return
    end

    for _, listener in ipairs(listeners[hookType]) do
        if listener.callbackTarget ~= nil then
            listener.callbackFunc(listener.callbackTarget, ...)
        else
            listener.callbackFunc(...)
        end
    end
end


-- events called from engine
---Called when the editor was started/initialized
function onStart()
    print("onStart")
end

---Called when an i3d file/scene is opened
-- @param string filepath
function onFileOpen(filepath)
    print("onFileOpen")
    _publish(HookType.ON_FILE_OPEN, filepath)
end

---Called when an external i3d file is imported
-- @param string filepath
-- @param string nodes array of imported node ids (first hierarchy level of the imported file resp. all nodes directly linked the rootNode of the scene)
-- @param boolean asReference file was imported "as reference"
function onFileImported(filepath, nodes, asReference)
    print("onFileImported", filepath, nodes)
    _publish(HookType.ON_FILE_IMPORTED, filepath, nodes)
end

---Called when current scene is saved
-- @param string filepath
function onSave(filepath)
    print("onSave")
    _publish(HookType.ON_SAVE, filepath)
end

---
-- @param entityId nodeId
-- @param boolean isSelected true if node was added to selected, false if it was removed
function onSelectionChanged(nodeId, isSelected)
    print("onSelectionChanged", nodeId, isSelected)
    _publish(HookType.ON_SELECTION_CHANGED, nodeId, isSelected)
end

---
-- @param entityId cloneNodeId
function onNodeCloned(cloneNodeId)
    print("onNodeCloned", cloneNodeId)
    _publish(HookType.ON_NODE_CLONED, cloneNodeId)
end


-- TODO: this could be very slow when deleting lots I assume, perhaps aggregating all deleted nodes as an array and issuing a single callback could be more performant
---Called for each deleted node (also for all child nodes of a parent is deleted)
-- @param entityId deletedNodeId
function onNodeDeleted(deletedNodeId)
    print("onNodeDeleted", deletedNodeId)
    _publish(HookType.ON_NODE_DELETED, deletedNodeId)
end

