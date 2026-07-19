# CafeBuilder

**CafeBuilder** is a premium, collaboration-first Flutter application designed to streamline the process of building and renovating coffee shops. It serves as a unified workspace that connects cafe owners, interior designers, and general contractors, ensuring that every phase—from initial AI consultation to final construction—is managed seamlessly.

##  Key Features

- **"Espresso & Form" Design System:** A sophisticated, minimalist UI/UX tailored for the coffee industry, featuring curated warm neutrals, sleek typography, and premium micro-interactions.
- **AI Design Assistant:** An interactive, premium chat interface where owners can get initial design consultations and generate project briefs.
- **Project Marketplace:** A dedicated space to broadcast AI-generated project briefs to a curated network of designers and contractors, or discover specialized construction services.
- **Design Review Workflow:** A robust package review system (`PackageReviewPage` and `FileReviewDetailPage`) allowing users to track file statuses (Approved, Need Review, Revision Requested), compare versions side-by-side, and leave precise feedback.
- **Collaboration Workspace:** Features a central dashboard (`CollaborationPage`) equipped with:
  - **Threaded Discussions:** Role-labeled chat threads (e.g., Designer vs. Contractor).
  - **Decision Logs & Meeting Notes:** Keep track of key decisions, client sign-offs, and site visit summaries.
  - **Pending Approvals:** Priority queue for materials and design checkpoints.
  - **Shared Assets:** Easy access to construction drawings, 3D renders, and material boards.
- **Role-Based Architecture:** Intelligent onboarding and contextual UI adapting to whether you are a *Shop Owner*, *Designer*, or *Contractor*.

##  Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version)
- Dart SDK
- Android Studio / Xcode / Visual Studio (for Windows builds)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/CafeBuilder.git
   cd CafeBuilder
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   # Make sure you have a connected device or an emulator running
   flutter run
   ```

## 📁 Project Structure

The codebase is organized primarily within the `lib/` directory:

- **`lib/theme/`**: Contains the core "Espresso & Form" design tokens, including `app_colors.dart` and typography setups.
- **`lib/pages/`**: Contains all UI screens, including:
  - `project_detail_page.dart`: The main project overview dashboard.
  - `design_packages_page.dart` & `package_review_page.dart`: The core design file presentation layer.
  - `file_review_detail_page.dart`: Detailed visual comparison and approval workflow.
  - `collaboration_page.dart`: Inter-role workspace and project tracking hub.
  - `thread_detail_page.dart` & `meeting_notes_page.dart`: Deep-dive views for communication.

## 🛠 Tech Stack
- **Framework:** Flutter / Dart
- **Design:** Custom Vanilla design system inspired by premium editorial layouts.

## 🤝 Contribution Guidelines
When contributing to this project, please adhere to the "Espresso & Form" design system. Avoid using raw colors inside UI files; always map your widgets to `AppColors`. Ensure that any new workflows support multi-role permissions.

---
*Built with ❤️ for coffee lovers and creators.*
