# Materials Intelligence — Manual Verification Guide

This guide covers checks that could not be completed in the development environment. It is written for someone who is new to Xcode. Complete the sections in order and record the result beside each checkbox.

## Important safety notes

- Use synthetic demonstration data only. Do not use this app as engineering approval or safety guidance.
- Do not mark a claim Reviewed or Verified unless you have independently checked its source.
- The project is intended for macOS 26 or later and Xcode 27 or later.
- A green build does not prove that the interface, iCloud, an iPhone/iPad, or Apple’s on-device model works.
- If a step cannot be performed, write `BLOCKED` and the reason. Do not treat it as a pass.

## 1. Prepare Xcode and the project

1. Start the Mac and make sure it is running macOS 26 or later. Choose **Apple menu → About This Mac** to check.
2. Open **Xcode** from Applications.
3. Open the project file:
   `MaterialsIntelligence.xcodeproj`
4. If Xcode asks whether to trust or open the project, choose **Open**.
5. At the top of the Xcode window, click the scheme/device selector. Choose:
   - Scheme: `MaterialsIntelligence`
   - Destination: **My Mac**
6. Choose **Product → Build** or press **⌘B**.
7. Confirm that Xcode reports **Build Succeeded**.
8. Click the Run button (triangle) or press **⌘R**.
9. If macOS asks whether the application may access files, choose **Allow** only when it is required by the test you are performing.
10. Keep the application open for the checks below.

Record:

- [ ] Project opened without errors.
- [ ] Build succeeded.
- [ ] Application launched on **My Mac**.
- [ ] Any error message, including a screenshot, was recorded.

If Build fails, stop and record the first red error from the Issue navigator (the triangle-with-exclamation icon on the left). Do not try to fix source code as part of this manual check.

## 2. Basic window, appearance, and accessibility check

Perform this section on every major page reachable from the sidebar.

1. Make the window wide, then narrow it by dragging an edge.
2. Make the window tall, then short.
3. Confirm that text remains readable, buttons remain visible, and no important content is permanently cut off.
4. Open **System Settings → Appearance** and test both **Light** and **Dark** appearance. Relaunch the app if the change is not immediately visible.
5. Use the sidebar to visit Overview, Materials, Claims, Library, Research, Explorer, Engineering Tools, and Engineering Agent when those pages are available.
6. Press **Tab** repeatedly. Confirm that keyboard focus moves through controls in a sensible order.
7. Activate a focused button with **Space** or **Return**.
8. Open **System Settings → Accessibility → VoiceOver**. Turn VoiceOver on with **⌘F5** (press it again to turn it off).
9. Move through the sidebar and key controls with VoiceOver. Confirm that buttons and fields have meaningful names.

Pass when the page remains usable at different sizes, in both appearances, with keyboard focus, and with VoiceOver. Record the page and exact control for every problem.

- [ ] Window resizing checked.
- [ ] Light appearance checked.
- [ ] Dark appearance checked.
- [ ] Keyboard navigation checked.
- [ ] VoiceOver checked.

## 3. Phase 3 authoring walkthrough

Use clearly synthetic names such as `TEST-Material-001` and `TEST-Source-001`.

1. Create a synthetic material, mechanism, component, standard, and source.
2. Open each new record and confirm its name and notes are retained after leaving and reopening the page.
3. Create a claim attached to the synthetic material and source.
4. Leave the claim Unverified. Confirm it is visibly distinguished from reviewed information.
5. Edit the claim and save it. Close and reopen the app to confirm persistence.
6. Review the claim only after checking its source. Confirm the status changes as expected.
7. Create a relationship between two synthetic records and open both ends of that relationship.
8. Attempt to delete a record that still has claims or relationships. Confirm the app prevents unsafe deletion and explains why.
9. Delete only a record with no remaining references, if the UI allows it.

- [ ] Create and edit records.
- [ ] Create, inspect, and review a claim.
- [ ] Create and inspect a relationship.
- [ ] Guarded deletion behaved correctly.
- [ ] Data survived relaunch.

## 4. Library file and relink checks

Prepare a small local text or PDF file that contains no private information.

1. Open **Library**.
2. Choose the control for adding/selecting a document.
3. In the macOS file picker, select the test file and confirm the selection.
4. Confirm that the document appears in the Library and can be associated with a synthetic record or claim.
5. Open the document using the app’s open control. Confirm macOS opens the correct file.
6. Quit the app with **MaterialsIntelligence → Quit MaterialsIntelligence**.
7. Relaunch it with **⌘R** in Xcode or from the built application. Confirm the Library entry remains.
8. In Finder, move the test file to another folder. Return to the app and try to open it.
9. Confirm the app reports that the reference is stale or unavailable and does not silently delete the Library metadata.
10. Use **Locate file…** or the equivalent relink control and choose the moved file.
11. Open it again and confirm the reference works.

- [ ] File picker opened and selected the intended file.
- [ ] File opened from the Library.
- [ ] Library entry survived relaunch.
- [ ] Moved-file state was reported safely.
- [ ] Relink restored access without losing metadata.

## 5. Search, Research, and Ask walkthrough

Use the supplied fixture files only as demonstration data. They are not engineering evidence.

1. Open **Research** and import one fixture JSON file from the repository’s `Fixtures` folder.
2. Inspect the package overview, entities, sources, claims, and relationships.
3. For at least one proposal, test **Accept**, **Reject**, **Reuse**, **Reset**, and edit where available. Confirm the displayed decision changes.
4. Cancel one staged session. Confirm it does not add knowledge.
5. Start another import and explicitly approve at least one safe synthetic proposal, then commit it.
6. Open Research history and confirm the original package and final result are inspectable.
7. Search for a distinctive synthetic name using the normal Search page.
8. Open **Claims** and review the imported claim only after checking its source. Confirm the claim status is visible.
9. Open **Ask** and ask a question that can be answered only from the reviewed synthetic claim.
10. Confirm the answer shows exact evidence references. If the local model is unavailable, confirm the app reports an unavailable state instead of using a cloud fallback.

- [ ] Import and proposal inspection.
- [ ] Accept/reject/reuse/reset/edit behavior.
- [ ] Cancel made no knowledge change.
- [ ] Commit and history behavior.
- [ ] Search found the committed synthetic content.
- [ ] Claims review gate behaved correctly.
- [ ] Ask showed evidence or an honest unavailable state.

## 6. Explorer, Why, comparison, and Engineering Tools

Create or import a small synthetic chain such as material → mechanism → standard → source.

1. Open **Explorer** and select the synthetic material.
2. Expand a first-hop and then a second-hop relationship.
3. Open a source or claim from the path. Confirm its provenance is visible.
4. Use **Explore** and then **Back**. Confirm navigation returns to the previous context.
5. Open two synthetic materials and compare them. Confirm the comparison shows stored narrative properties and evidence, without inventing numeric suitability.
6. Open a claim and select **Why**. Confirm the path begins with the selected claim and shows only recorded relationships.
7. In **Engineering Tools**, create a synthetic `assessment_rule` claim using `ENGINEERING_TOOLS.md` and the actual mechanism ID shown by the app. Review it, run at the inclusive boundary (10 °C and 2 MPa), then outside the rule range. Confirm matching, unresolved/out-of-scope behavior, evidence links and export.
8. Select **Material comparison**, choose two synthetic materials, and enter exact synthetic scope fields. Add one source-backed `material_selection_rule` per candidate, mark each Reviewed, and confirm only exact-scope rules support consideration or flag exclusion. Change one scope field and confirm the rule no longer applies. Add opposing matching rules and confirm a conflict is shown.
9. Select **Vendor qualification** and enter synthetic vendor, facility, product, process, heat-treatment, test, observation, finding, corrective-action and history details. Run it, inspect the source-linked evidence and missing fields, export, and reopen the saved run.
10. Select **Failure investigation**, enter synthetic component/material and observations, select a mechanism, and inspect candidate evidence. Confirm user-entered supportive/contradictory observations remain attributed to the user and no cause is assigned.
11. Select **Fit-for-purpose review** and create a source-backed `fit_for_purpose_requirement` claim using the JSON in `ENGINEERING_TOOLS.md`. Mark it Reviewed/Verified, enter the exact service scope and one `key = value` parameter, then try a matching, differing, missing and out-of-scope value. Confirm the report labels these as text checks and never a compliance verdict.
12. Open **Engineering Agent**, run each workflow with matching task wording, inspect the selected tool and evidence IDs, and reopen the matching local history entries. Try a mismatched task and confirm it stops without a conclusion.

- [ ] Explorer multi-hop path.
- [ ] Source/claim provenance.
- [ ] Explore and Back.
- [ ] Material comparison.
- [ ] Why path.
- [ ] Five engineering workflows, scoped-rule matching and conflict handling.
- [ ] Vendor/failure user-input attribution and local history.
- [ ] Fit-for-purpose text match, mismatch, missing, and out-of-scope behavior.
- [ ] Agent workflow routing, evidence IDs, mismatch stop, and audit history.
- [ ] Report export for each workflow.

## 7. Engineering Agent walkthrough

Use reviewed synthetic rules and synthetic records only.

1. Open **Engineering Agent**.
2. Select a workflow and enter a matching request; for degradation, use `screen TEST-Material-001 for TEST-Mechanism-001`.
3. Complete its structured fields. For material comparison, vendor qualification, failure investigation and fit-for-purpose, use the corresponding forms and source-backed records.
4. Run once with explanation disabled. Confirm the report contains tools, evidence, sources, gaps, assumptions, and claim links.
5. Export the report and reopen Agent history. Confirm the structured request remains available after relaunch.
6. Enter a task that does not match the selected workflow. Confirm the app stops without an engineering conclusion.
7. Switch to Research mode. Confirm it produces a research brief/handoff only; it must not browse or silently change knowledge.
8. On a model-ready Mac, repeat with explanation enabled. Confirm the explanation is labelled as local model inference and its citation IDs resolve.

- [ ] Bounded assessment run.
- [ ] Evidence and citation inspection.
- [ ] Export and durable history.
- [ ] Unsupported request stopped safely.
- [ ] Research mode produced a brief only.
- [ ] Optional explanation passed or honestly reported unavailable.

## 8. Real Apple model check

This requires an eligible Mac with Apple’s Foundation Models available and ready.

1. Confirm the Mac is signed in as required by the current macOS release and has the model available. If the app reports `modelNotReady` or unavailable, record that exact status.
2. In Ask, ask a question based only on a reviewed synthetic claim.
3. In Agent, enable the optional explanation and run the same bounded synthetic case.
4. Confirm generation completes, stays local, and cites retrieved claim IDs.
5. Repeat after turning off or making the model unavailable, if your Mac provides a supported way to do so. Confirm the app returns a clear unavailable state and preserves the deterministic report.

Never treat a generated explanation as independently verified engineering knowledge.

- [ ] Model-ready Ask response.
- [ ] Model-ready Agent explanation.
- [ ] Citation IDs resolve.
- [ ] Unavailable-model behavior.

## 9. Signed iCloud and device checks

Do this only if you intentionally want to test the optional Personal Vault. It requires an Apple development team, matching bundle identifiers, CloudKit setup, and an iPhone or iPad signed into the same iCloud account.

### Xcode setup

1. In the project navigator, click the project’s blue icon.
2. Select the **MaterialsIntelligence** macOS target, then **Signing & Capabilities**.
3. Select your Apple development team and enable automatic signing if appropriate for your team.
4. Add/enable the iCloud capability and CloudKit for the Personal Vault configuration.
5. Repeat for the universal mobile target.
6. Confirm the container identifier is exactly `iCloud.com.materialsintelligence.app`.
7. Use the **Development** CloudKit environment. Do not deploy a production schema for this test.
8. In CloudKit Console, create/allow record type `PersonalVault` with a payload asset and integer version field, as described in `MOBILE_SYNC.md`.
9. Build both the Mac target and the mobile target again. Record any signing or entitlement error exactly.

### Mac-to-device transfer

1. Run the signed Mac app.
2. Open Personal Vault and opt in for the session.
3. Create a synthetic reference and choose **Sync now**.
4. Run the mobile app on an iPhone first. Opt in, choose **Sync now**, inspect the incoming snapshot, and explicitly apply it.
5. Confirm the synthetic record is readable on the phone.
6. Repeat on an iPad and confirm the iPad uses split navigation while the iPhone uses collapsed navigation.
7. Enable Airplane Mode on the phone and relaunch the app. Confirm local reading and search still work.

### Conflict and recovery

1. On both Mac and phone, edit the same synthetic data while offline.
2. Bring one device online and sync it.
3. Bring the second device online and sync it.
4. Confirm the app requires review and does not silently overwrite one version.
5. Choose a whole-snapshot resolution deliberately and confirm the recovery snapshot is offered.
6. Restore the recovery snapshot and confirm the current content is preserved as the next recovery point.
7. Archive/delete a synthetic claim on Mac and confirm the change propagates only after review.

- [ ] Signed Mac build.
- [ ] Signed iPhone build/run.
- [ ] Signed iPad build/run.
- [ ] Mac-to-device transfer.
- [ ] Offline reopen/search.
- [ ] Conflict review, resolution, and recovery.
- [ ] Reviewed archive/delete propagation.

If signing, CloudKit, or device setup is unavailable, mark Phase 9 **UNVERIFIED**, not passed.

## 10. Final results record

For each failed or blocked item, record:

- Date and macOS/Xcode version
- Mac model, and iPhone/iPad model if applicable
- Section and step number
- What you expected
- What happened
- Exact error text
- Screenshot or exported report path, if available

Full operational acceptance requires the GUI, file, and model checks plus signed iCloud/device checks. Claim timestamp preservation is corrected and covered by regression checks; this guide still requires a real signed device/account transfer.
