-- MARKER_E063_REVERT beta-two-side-mail

DELETE FROM `rbac_default_permissions` WHERE `permissionId` = 27 AND `realmId` = 2;
