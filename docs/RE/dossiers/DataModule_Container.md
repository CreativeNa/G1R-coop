# DataModule_Container

`class` in `/Script/G1R`, 3 own properties, 30 own functions.

Inheritance: `Object` → `DataModule` → `DataModule_Container`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 64 | 312 | StructProperty | `m_Inventory` | `StructProperty(ReplicatedInventoryMap)` |
| 376 | 312 | StructProperty | `m_DefaultInventory` | `StructProperty(ReplicatedInventoryMap)` |
| 760 | 80 | MapProperty | `QuickMemoryItems` | `MapProperty(EnumProperty,StructProperty(ItemMapWrapper))` |

## Functions

* `Server_RefreshInventory`
* `Server_ReattachIfNeeded`
* `Server_PickWorldItem`
* `Server_MoveItemTo`
* `Server_MoveItemFromActorToOtherActor`
* `Server_GetItemsFromContainerInv`
* `Server_Debug_EmptyInventory`
* `Server_ConsumeItemOfType`
* `Server_ConsumeItem`
* `Server_AddNewItem`
* `Server_AddAllItemsFromContainer`
* `Multicast_RefreshInventory`
* `Multicast_PickWorldItem`
* `Multicast_MoveItemTo`
* `Multicast_GetItemsFromContainerInv`
* `Multicast_Debug_EmptyInventory`
* `Multicast_ConsumeItemOfType`
* `Multicast_ConsumeItem`
* `Multicast_AddNewItem`
* `Multicast_AddAllItemsFromContainer`
* `HasItemWithUniqueName`
* `HasItemOnAnyQuickInventory`
* `HasItemOnAnyInventory`
* `HasItemMain`
* `GetItemsInConst`
* `GetItemsIn`
* `GetFirstItemWithUniqueName`
* `GetFirstItemWithType`
* `ConsumeItemOfTypeOnAnyInventory`
* `ConsumeItemOfType`
