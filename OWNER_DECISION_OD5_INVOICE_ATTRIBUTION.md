# OWNER DECISION — OD5 INVOICE ATTRIBUTION RESOLUTION

## Decision Identity

OWNER_DECISION_ID = OD5
DECISION_STATUS = RESOLVED
DECISION_AUTHORITY = PRODUCT_OWNER
SCOPE = PHASE_O_INVOICE_BRANDING_DELIVERY

## Authoritative Attribution Text

OD5_EXACT_ATTRIBUTION_TEXT = تم التطوير بواسطة I Tech للتكنولوجيا

This wording is exact and authoritative.

It MUST be rendered exactly as:

**تم التطوير بواسطة I Tech للتكنولوجيا**

No alternative Arabic wording, English translation, abbreviation, punctuation change, branding substitution, or inferred equivalent is authorized unless a later explicit Owner Decision supersedes this decision.

## Editability Policy

OD5_EDITABILITY_POLICY = FIXED_NON_EDITABLE

The I Tech attribution:

* MUST NOT be editable by the shop owner.
* MUST NOT be removable from application settings.
* MUST NOT be replaced by the shop name.
* MUST NOT be reused as the shop's own invoice identity.
* MUST remain logically separate from user-configurable shop branding.
* MUST appear only in the attribution/manufacturer slot defined by the governing Phase O architecture.
* MUST NOT override or interfere with the shop's configured name, logo, address, phone number, tax information, or other invoice identity fields.

## Branding Separation Rule

SHOP_IDENTITY = USER_CONFIGURABLE

ITECH_ATTRIBUTION = FIXED_PRODUCT_ATTRIBUTION

The invoice therefore has two independent identity domains:

1. **Shop identity**

   * Configured by the user.
   * Represents the merchant issuing the invoice.

2. **I Tech attribution**

   * Fixed by the product owner.
   * Represents the software/product attribution only.
   * Exact text:
     `تم التطوير بواسطة I Tech للتكنولوجيا`

The implementation MUST NOT visually or semantically imply that I Tech للتكنولوجيا is the seller, merchant, customer, tax entity, or invoice issuer unless the configured shop identity itself independently states so.

## Scope Constraints

This Owner Decision resolves OD5 only.

It does NOT authorize:

* Phase P work.
* Invoice-numbering changes.
* Database schema changes.
* Supabase migrations.
* Licensing changes.
* Cloud-sync expansion.
* Android package-ID changes.
* Unrelated refactoring.
* Modification or deletion of preserved/sacred artifacts.

## Governance Effect

OD5_STATUS = RESOLVED

OD5_EXACT_ATTRIBUTION_TEXT = تم التطوير بواسطة I Tech للتكنولوجيا

OD5_EDITABILITY_POLICY = FIXED_NON_EDITABLE

PHASE_O_IMPLEMENTATION_OD5_GATE = CLEARED

The previous forensic result:

`BLOCKED_PHASE_O_IMPLEMENTATION_OD5_UNRESOLVED`

is therefore resolved by this explicit Owner Decision.

After this decision is recorded authoritatively in repository governance and locked according to the existing commit/tag discipline:

`NEXT_AUTHORIZED_SESSION = PHASE_O_IMPLEMENTATION`

Implementation must resume from the frozen Phase O planning baseline without expanding scope.