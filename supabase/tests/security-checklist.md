# Cloud Collab security test checklist

Run these checks with two or more Supabase Auth users after applying the migration. Each denied operation should be verified both through the UI and by issuing the equivalent Supabase query from the browser console.

- [ ] An unauthenticated client cannot select workspaces, members, pages, or invitations.
- [ ] A member can select only workspaces, members, and pages for workspaces they belong to.
- [ ] A viewer cannot insert, update, or delete pages.
- [ ] An editor can create/update/delete pages but cannot update or delete memberships.
- [ ] An admin can manage non-owner roles and invitations but cannot delete a workspace or change the owner.
- [ ] Only the owner can delete a workspace.
- [ ] A page parent from another workspace is rejected by the composite foreign key.
- [ ] A page update made with a stale `updated_at` returns no row and does not overwrite the newer content.
- [ ] Invitation tokens are accepted only once, before expiry, and only by the matching auth email.
- [ ] A revoked or expired invitation cannot create a membership.
- [ ] A client cannot assign itself the `owner` role or invite an owner role.

The migration deliberately uses database-enforced policies and functions for these checks; frontend role checks are not treated as security boundaries.
