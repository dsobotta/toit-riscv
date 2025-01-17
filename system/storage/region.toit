// Copyright (C) 2023 Toitware ApS.
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; version
// 2.1 only.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// The license can be found in the file `LICENSE` in the top level
// directory of this repository.

import .storage show StorageServiceProvider

import binary show LITTLE_ENDIAN
import encoding.tison
import system.services show ServiceResource
import system.storage show Region
import uuid

import ..flash.allocation
import ..flash.registry

class FlashRegionResource extends ServiceResource:
  static NAMESPACE ::= "flash:region"

  client_/int
  handle_/int? := null

  constructor provider/StorageServiceProvider .client_ --offset/int --size/int:
    super provider client_
    try:
      handle := serialize_for_rpc
      flash_grant_access_ client_ handle offset size
      handle_ = handle
    finally: | is_exception _ |
      if is_exception: close

  revoke -> none:
    if not handle_: return
    flash_revoke_access_ client_ handle_
    handle_ = null

  on_closed -> none:
    revoke

  static open provider/StorageServiceProvider client/int -> List
      --path/string
      --capacity/int?:
    registry := provider.registry
    id := uuid.uuid5 NAMESPACE path
    allocation := find_allocation_ registry --id=id --if_absent=:
      if not capacity: throw "FILE_NOT_FOUND"
      // Allocate enough space for the requested capacity. We need
      // an extra page for the flash allocation header, which is
      // also where we store additional properties for the region.
      new_allocation_ registry --id=id --path=path --size=capacity + FLASH_REGISTRY_PAGE_SIZE
    offset := allocation.offset + FLASH_REGISTRY_PAGE_SIZE
    size := allocation.size - FLASH_REGISTRY_PAGE_SIZE
    if capacity and size < capacity: throw "Existing region is too small"
    resource := FlashRegionResource provider client --offset=offset --size=size
    return [
        resource.serialize_for_rpc,
        offset,
        size,
        FLASH_REGISTRY_PAGE_SIZE_LOG2,
        Region.MODE_WRITE_CAN_CLEAR_BITS_
    ]

  static delete registry/FlashRegistry -> none
      --path/string:
    id := uuid.uuid5 NAMESPACE path
    allocation := find_allocation_ registry --id=id --if_absent=: return
    offset := allocation.offset + FLASH_REGISTRY_PAGE_SIZE
    size := allocation.size - FLASH_REGISTRY_PAGE_SIZE
    if flash_is_accessed_ offset size: throw "ALREADY_IN_USE"
    registry.free allocation

  static list registry/FlashRegistry -> List:
    result := []
    registry.do: | allocation/FlashAllocation |
      if allocation.type != FLASH_ALLOCATION_TYPE_REGION: continue.do
      properties_size := LITTLE_ENDIAN.uint16 allocation.metadata 0
      catch:
        properties := tison.decode allocation.content[..properties_size]
        result.add properties["path"]
    return result

  static find_allocation_ registry/FlashRegistry [--if_absent] -> FlashAllocation
      --id/uuid.Uuid:
    registry.do: | allocation/FlashAllocation |
      if allocation.type != FLASH_ALLOCATION_TYPE_REGION: continue.do
      if allocation.id == id: return allocation
    return if_absent.call

  static new_allocation_ registry/FlashRegistry -> FlashAllocation
      --id/uuid.Uuid
      --path/string
      --size/int:
    properties := tison.encode { "path": "flash:$path" }
    reservation := registry.reserve size
    if not reservation: throw "OUT_OF_SPACE"
    metadata := ByteArray 5: 0xff
    LITTLE_ENDIAN.put_uint16 metadata 0 properties.size
    return registry.allocate reservation
        --type=FLASH_ALLOCATION_TYPE_REGION
        --id=id
        --metadata=metadata
        --content=properties

// --------------------------------------------------------------------------

flash_grant_access_ client handle offset size:
  #primitive.flash.grant_access

flash_is_accessed_ offset size:
  #primitive.flash.is_accessed

flash_revoke_access_ client handle:
  #primitive.flash.revoke_access
