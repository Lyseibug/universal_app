# PDT Mobile App Setup & Screens Reference

Generated: 2026-07-06

---

## 1. SYSTEM OVERVIEW

### Available Modules (6 modules)
| Module Key | Module Label | Icon | Sequence |
|---|---|---|---|
| line1 | Compound Production | — | 0 |
| receiving | Receiving | inbox | 10 |
| picking | Picking | list | 20 |
| inventory | Inventory | cart | 30 |
| supervisor_tools | Supervisor Tools | shield | 40 |
| support | Support | person | 90 |

### Available Screens (14 screens)
| Screen Key | Screen Label | Module | API Module | Roles Required |
|---|---|---|---|---|
| material_loading | Material Loading | line1 | — | System Manager |
| mixer_loading | Mixer Loading | line1 | — | System Manager |
| weighing_load | Weighing Load | line1 | — | System Manager |
| compound_lab_test | Compound Lab Test | line1 | — | System Manager |
| calendering | Calendering | line1 | — | System Manager |
| manufacturing_mr | Manufacturing MR | line1 | — | System Manager |
| po_reception | PO Reception | receiving | — | System Manager |
| grn_putaway | Bin Allocation | receiving | grn | System Manager |
| pick_list | Pick List | picking | pick | System Manager |
| bag_view | Bag View | inventory | — | System Manager |
| physical_inventory | Physical Inventory | inventory | physical_inventory | System Manager |
| lot_browser | LOT Browser | supervisor_tools | lot | System Manager |
| manual_transfer | Manual LOT Transfer | supervisor_tools | lot | System Manager |
| support | Chat / Raise Issue | support | notifications | System Manager |

---

## 2. AVAILABLE WORKSTATIONS (139 total)

### Line 1 Production
- `L1B1` (Blender 1)
- `L1C1` - `L1C4` (Calendering 1-4)
- `L1G1` - `L1G4` (Grinding 1-4)
- `L1P1` - `L1P7` (Packaging 1-7)
- `L1QC1` (Quality Control 1)
- `L1R1` - `L1R5` (Receiving 1-5)

### Line 2 Production
- `L2B1`, `L2C1` - `L2C4`, `L2G1` - `L2G4`, `L2P1` - `L2P7`, `L2QC1`, `L2R1` - `L2R5`

### Line 3 Production
- `L3B1`, `L3C1` - `L3C3`, `L3G1` - `L3G3`, `L3P1` - `L3P3`, `L3QC1`, `L3R1` - `L3R3`

### Line 4 Production
- `L4B1`, `L4C1` - `L4C4`, `L4G1` - `L4G4`, `L4P1` - `L4P7`, `L4QC1`, `L4R1` - `L4R5`

### Material/Mixer
- `Mixer`, `M1B1`, `M1C1` - `M1C4`, `M1G1` - `M1G4`, `M1P1` - `M1P7`, `M1QC1`, `M1R1` - `M1R5`

### Receiving/Putaway
- `Reception` (generic receiving area)
- `Putaway` (generic put-away area)
- `Chemical Weighing` (specialized station)
- `Calender` (calendering station)

### Sleeve/Packing
- `A1B1`, `A1P1`, `A1QC1`
- `S1C1` - `S1C4`, `S1G1` - `S1G4`

### Shipping/Returns
- `R1G1` - `R1G5` (Shipping Return Group 1-5)
- `R2G1` - `R2G5` (Shipping Return Group 2-5)
- `R3G1` - `R3G5` (Shipping Return Group 3-5)

---

## 3. SWALIH USER CONFIGURATION ✓

### Employee Setup
- **Employee Code:** `E0106`
- **Name:** Muhammed Swalih Vallikkadan
- **User ID:** `swalih.v@universal-rbm.com`
- **Status:** ✓ Linked to User

### Roles
- **System Manager** ✓ (required for PDT screens)
- Employee ✓
- Plus 50+ other roles (Stock User, Manufacturing User, Stock Manager, etc.)

### Worker Workstation Assignment
- **Assignment ID:** `v7u5pnffpl`
- **Worker:** `E0106` ✓
- **Assigned Workstations:** `Reception, Mixer, Chemical Weighing, Calender, Putaway` ✓
- **Supervisor:** `E0081` ✓
- **Active:** Yes ✓

### Current Worker Session
- **Session ID:** `WS-0004`
- **Active:** Yes ✓
- **Workstation:** `Reception`
- **Login Time:** 2026-07-06 11:09:32

### Expected Mobile App Flow
1. ✓ Splash screen reads active Worker Session
2. ✓ Routes to `/home` (not workspace picker)
3. ✓ Shows all 6 module groups
4. ✓ All 14 screens available (user has System Manager role)
5. ✓ Can access all 5 assigned workstations

---

## 4. TROUBLESHOOTING CHECKLIST

### If swalih still sees workspace picker on every app restart:
- [ ] Verify Worker Session `WS-0004` is still `is_active=1`
- [ ] Check if session was deactivated by logout or session timeout
- [ ] Manually restart: **User** → **Worker Session** → Find latest row → Set `is_active=1`

### If screens don't appear:
- [ ] Confirm user still has **System Manager** role
- [ ] Refresh mobile app menu: Pull down on home screen, or re-login

### If workstation assignments don't work:
- [ ] Verify `workstations` field is NOT NULL (currently: `Reception,Mixer,Chemical Weighing,Calender,Putaway`)
- [ ] Ensure each workstation name exists in **Workstation** list (all are valid ✓)

---

## 5. TO ADD NEW USERS TO PDT

Follow this order for each new user (e.g., for another operator):

1. **Create/Link Employee**
   - Desk → Employee → New
   - Set `user_id` = their User record
   - Save (note the Employee code, e.g., E0107)

2. **Set User Roles**
   - Desk → User → Find their user record
   - Add role: **System Manager** (required)
   - Add role: **Employee**
   - Save

3. **Create Worker Workstation Assignment**
   - Desk → Worker Workstation Assignment → New
   - **worker:** [Employee code from step 1]
   - **workstations:** comma-separated workstation names (e.g., `L1B1, L1P1, L1QC1`)
   - **supervisor:** [Pick an Employee who supervises]
   - **is_active:** ✓ (checked)
   - Save

4. **Test on Mobile**
   - Fresh app start (logout if logged in)
   - Login with their credentials
   - Should route to workspace picker → home screen → all modules/screens visible

---

## 6. NOTES

- **Line 2 screens missing:** The app supports Line 2 (belt/sleeve building, curing, processing, labelling, QC, packing, tool status) but these screens are **not yet active** in PDT Screen config. Contact DevOps to enable if needed.
- **All workstations are naming conventions**, not pre-configured with special permissions. Each Workstation record is a bare-bones entity (name + optional warehouse).
- **Screen visibility is purely role-based:** Only System Manager can see any screen. More granular access (e.g., "only Receiving workers see po_reception") would require:
  - Creating custom roles for each area
  - Updating PDT Screen role requirements
  - See GOLIVE-DOC §6 for details

