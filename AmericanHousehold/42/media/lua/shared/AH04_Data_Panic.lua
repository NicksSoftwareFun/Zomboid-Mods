--------------------------------------------------------------------------------
-- AH04_Data_Panic.lua — §10.2 the panic layer. PURE DATA.
-- The one setpiece exception: a uniform, lore-baked reduction on food, gun,
-- pharmacy, and electronics/liquor RETAIL, written into the pools so every
-- store reads post-panic because the panic HAPPENED — not because a die
-- rolled. rollsFactor lowers the pool's roll count (the real "how much
-- remains" lever; uniform weight scaling is a no-op — see AH12 header).
--
-- Only applied when SetpieceStocking = Panic (default). Full stocking skips
-- this entirely (P10). Police is NOT here — the armory was manned (§10.4).
-- The stripped-useless / untouched-priceless contrast between adjacent
-- storefronts (electronics gutted, hardware full) is the P12 monument.
--------------------------------------------------------------------------------

AH = AH or {}
AH.Data = AH.Data or {}

AH.Data.Panic = {
    -- Grocery / Gigamart FOOD front of house: 20-40% remaining, stripped
    -- shelves. Only food — nobody panic-bought Gigamart's tools/farming.
    { rollsFactor = 0.3, note = "grocery/gigamart food front 20-40%", pools = {
        "GigamartCannedFood","GigamartBreakfast","GigamartDryGoods","GigamartCandy",
        "GigamartCrisps","GigamartSauce","GigamartSpices","GigamartBakingMisc",
        "GigamartBottles",
        "GroceryStandFruits1","GroceryStandFruits2","GroceryStandFruits3",
        "GroceryStandLettuce","GroceryStandVegetables1","GroceryStandVegetables2",
        "GroceryStandVegetables3","GroceryStandVegetables4","GroceryStandVegetables5",
    } },
    -- Grocery STOCKROOM: 60-80% — the panic hit shelves, not the back. This
    -- is the play: check the stockroom.
    { rollsFactor = 0.7, note = "grocery stockroom 60-80%", pools = {
        "GroceryStorageCrate1","GroceryStorageCrate2","GroceryStorageCrate3",
    } },

    -- Gun store DISPLAY / sale floor: 10-30%, cleaned out first.
    { rollsFactor = 0.2, note = "gun store display 10-30%", pools = {
        "GunStorePistols","GunStoreRifles","GunStoreShotguns","GunStoreCases",
        "GunStoreDisplayCase","GunStoreCounter","GunStoreShelf",
    } },
    -- Gun store locked storage: 50-70% — what the owner didn't sell.
    { rollsFactor = 0.6, note = "gun store locked storage 50-70%", pools = {
        "GunStoreAmmunition","GunStoreMagsAmmo",
    } },

    -- Pharmacy OTC / cosmetics front: 20-40% — painkillers grabbed.
    { rollsFactor = 0.3, note = "pharmacy OTC front 20-40%", pools = {
        "PharmacyCosmetics","PharmacyGlasses",
    } },
    -- Behind-counter drugs: 60-80% — panic buyers didn't know to want the
    -- amoxicillin. Antibiotics were NOT panic-bought (design point), so the
    -- reduction here is light.
    { rollsFactor = 0.7, note = "pharmacy behind-counter 60-80%", pools = {
        "MedicalClinicDrugs",
    } },

    -- Electronics retail: 10-30% (v0.6, P12) — TVs/VCRs/camcorders that will
    -- never be plugged in again.
    { rollsFactor = 0.2, note = "electronics retail 10-30%", pools = {
        "ElectronicStoreAppliances","ElectronicStorePhones","ElectronicStoreMusic",
        "ElectronicStoreComputers","ElectronicStoreHAMRadio","ElectronicStoreMisc",
        "GigamartHouseElectronics",
    } },
    { rollsFactor = 0.5, note = "electronics boxed stock 40-60%", pools = {
        "ElectronicStoreCases",
    } },

    -- Liquor wall stripped: 10-30%.
    { rollsFactor = 0.2, note = "liquor retail 10-30%", pools = {
        "LiquorStoreBeer","LiquorStoreBeerFancy","LiquorStoreWhiskey","LiquorStoreVodka",
        "LiquorStoreRum","LiquorStoreGin","LiquorStoreScotch","LiquorStoreTequila",
        "LiquorStoreBrandy","LiquorStoreWine","LiquorStoreWineFancy","LiquorStoreMix",
    } },
}
