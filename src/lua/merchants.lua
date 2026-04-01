--[[
    VendorItemData const* items = vendorEntry ? sObjectMgr->GetNpcVendorItemList(vendorEntry) : vendor->GetVendorItems();
    VendorItem const* item = items->GetItem(slot)
    ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(item->item)

    data << vendorGUID; -- of type ObjectGUID
    data << uint8(count)
    data << uint32(slot + 1);       // client expects counting to start at 1
    data << uint32(item->item);
    data << uint32(itemTemplate->DisplayInfoID);
    data << int32(leftInStock);
    data << uint32(price);
    data << uint32(itemTemplate->MaxDurability);
    data << uint32(itemTemplate->BuyCount);
    data << uint32(item->ExtendedCost);
--]]

-- SMSG_LIST_INVENTORY                             = 0x19F,
-- CMSG_BUY_ITEM                                   = 0x1A2,
-- CMSG_BUY_ITEM_IN_SLOT                           = 0x1A3,

PLAYER_RANDOM_ITEMS = { }

for i = 1, 10 do
    PLAYER_RANDOM_ITEMS[i] = {
        slot = i,
        leftInStock = 10,
        price = math.random(100, 1000),
        item         = { id = math.random(500, 5000), ExtendedCost = 0, },
        itemTemplate = { DisplayInfoID = 0, MaxDurability = 10, BuyCount = 1, },
    }
end


local function SendUpdatedVendorList(event, packet, player)
    print("SendUpdatedVendorList")
    print("eventID: " .. event)
    print("player: " .. player)
    print("data: " .. packet)
    local opcode = 0x19F
    local packet_size = packet:GetSize()
    local packet = CreatePacket(opcode, packet_size)
    for i = 1, 10 do
        local item = PLAYER_RANDOM_ITEMS[i]
        packet:WriteGUID (vendorGUID)
        packet:WriteULong(i)
        packet:WriteULong(item.id)
        packet:WriteULong(item.itemTemplate.DisplayInfoID)
        packet:WriteLong (item.leftInStock)
        packet:WriteULong(item.price)
        packet:WriteULong(item.itemTemplate.MaxDurability)
        packet:WriteULong(item.itemTemplate.BuyCount)
        packet:WriteULong(item.ExtendedCost)
    end
    player:SendPacket(packet)
end

local function ReceiveItemBought()

end

local PACKET_EVENT_ON_PACKET_RECEIVE = 5
local PACKET_EVENT_ON_PACKET_SEND    = 7
local SMSG_LIST_INVENTORY            = 0x19F
local CMSG_BUY_ITEM                  = 0x1A2
local CMSG_BUY_ITEM_IN_SLOT          = 0x1A3
RegisterPacketEvent( SMSG_LIST_INVENTORY,   PACKET_EVENT_ON_PACKET_SEND,    SendUpdatedVendorList )
RegisterPacketEvent( CMSG_BUY_ITEM,         PACKET_EVENT_ON_PACKET_RECEIVE, ReceiveItemBought     )
RegisterPacketEvent( CMSG_BUY_ITEM_IN_SLOT, PACKET_EVENT_ON_PACKET_RECEIVE, ReceiveItemBought     )




-- example
local function SendCreatureQueryResponse(player, data)
	local packet = CreatePacket(97, 100)
	packet:WriteULong(data[1])
	packet:WriteString(data[2] or "")
	packet:WriteUByte(0)
	packet:WriteUByte(0)
	packet:WriteUByte(0)
	packet:WriteString(data[3] or "")
	packet:WriteString(data[4] or "")
	packet:WriteULong(data[5])
	packet:WriteULong(data[6])
	packet:WriteULong(data[7])
	packet:WriteULong(data[8])
	packet:WriteULong(data[9])
	packet:WriteULong(data[10])
	packet:WriteULong(data[11])
	packet:WriteULong(data[12])
	packet:WriteULong(data[13])
	packet:WriteULong(data[14])
	packet:WriteFloat(data[15])
	packet:WriteFloat(data[16])
	packet:WriteUByte(data[17])
	packet:WriteULong(0)
	packet:WriteULong(0)
	packet:WriteULong(0)
	packet:WriteULong(0)
	packet:WriteULong(0)
	packet:WriteULong(0)
	packet:WriteULong(data[18])
	player:SendPacket(packet)
end
