// TODO: Add a build option for this
// The `CLAY_COLOR` override is needed to use the raylib's `Color` type.
#define CLAY_COLOR struct { uint8_t r, g, b, a; }

// TODO: Waiting on https://github.com/nicbarker/clay/pull/112 to be merged.
#define CLAY_IMPLEMENTATION
#include "clay.h"
// #include <clay.h>

// TODO: Is index used correctly? `CLAY_IDI_LOCAL` just discards it.
CLAY_WASM_EXPORT("Clay_GetElementIdLocalWithIndex")
Clay_ElementId Clay_GetElementIdLocalWithIndex(Clay_String idString, uint32_t index) {
    Clay_LayoutElement *parentElement = Clay__GetOpenLayoutElement();
    return Clay__HashString(idString, parentElement->childrenOrTextContent.children.length + 1 + index , parentElement->id);
}

Clay_ElementId Clay__GetOpenLayoutElementId() {
    return CLAY__INIT(Clay_ElementId){ .id = Clay__GetOpenLayoutElement()->id, .stringId = CLAY__STRING_DEFAULT };
}

// TODO: Cache this id and report an error in `Clay__ElementPostConfiguration()` if there is a
// different id supplied. Afterwards reset the cache.
bool Clay__NextHovered() {
    Clay_LayoutElement* parentElement = Clay__GetOpenLayoutElement();
    Clay_ElementId nextId = Clay__HashNumber(parentElement->childrenOrTextContent.children.length, parentElement->id);

    for (int i = 0; i < Clay__pointerOverIds.length; ++i) {
        if (Clay__ElementIdArray_Get(&Clay__pointerOverIds, i)->id == nextId.id) {
            return true;
        }
    }
    return false;
}
