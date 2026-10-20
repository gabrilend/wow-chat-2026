-- MARKER_E062_REVERT beta-two-side-trade

DELETE FROM `rbac_default_permissions` WHERE `permissionId` = 51 AND `realmId` = 2;
