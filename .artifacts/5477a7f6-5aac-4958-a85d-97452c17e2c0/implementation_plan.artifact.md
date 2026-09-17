# Implementation Plan - Display Detailed Current Location

The user wants to display their exact current location name (address) prominently in the app. Currently, the app fetches a basic address and displays it in a small tag within the prayer card.

## Proposed Changes

### Core Services

#### [MODIFY] [prayer_service.dart](file:///home/sigma/StudioProjects/ghiras/lib/core/services/prayer_service.dart)
- Enhance the address building logic in `updateSettings()` to include more details from the `Placemark` object (e.g., `name`, `subLocality`, `locality`).
- Ensure the address is localized to Arabic.
- Add logic to handle cases where some fields might be empty or redundant.

### Home Feature

#### [MODIFY] [home_screen.dart](file:///home/sigma/StudioProjects/ghiras/lib/features/home/home_screen.dart)
- Update the UI to display the location name more prominently.
- Add the location name to the greeting section at the top of the screen for better visibility.
- Increase the font size of the location name in the prayer card.
- Add a refresh icon/button next to the location name to allow the user to manually trigger a location update.

## Verification Plan

### Automated Tests
- No specific automated tests required for this UI enhancement, but I will verify the code compiles without errors.

### Manual Verification
- Run the app on an emulator/device.
- Verify that the location name appears at the top of the screen and in the prayer card.
- Test the refresh button to ensure it updates the location name correctly.
- Verify that the address is detailed (e.g., "Street Name, Neighborhood, City").
