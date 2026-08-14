/// Shared inspiration content — the same catalog backs both the "Gallery"
/// tab ([DiscoveryPage]) and Home's "Inspiration for you" section. They
/// used to keep two separate, out-of-sync lists; this is the single
/// source of truth both pull from now.
class InspirationItem {
  final String title;
  final String category;
  final String imageUrl;
  final double aspectRatio;

  const InspirationItem({
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.aspectRatio,
  });
}

const List<InspirationItem> kInspirationCatalog = [
  InspirationItem(
    title: 'The Serene Oak Nook',
    category: 'Japandi',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuA0zfL4zRZixYzd_GZJ-DN7G41T7Fwc1-_up8vdESgUwp5LH15zA76_f2V3drY7ENi0_Gv_a7EUOnphS0EkhFPLiTtTmoRcS0qKzJ8Mkj4XNTpsL10sB0yLJkRvC-jA7kh9-W9vyU2bwTLOEPDuV5bU56WerX2pr6NKQfMZ9u2BNuwYAazaYiw2lCmsE2SGjkm2SMP0rkmOXkO0BgtwsZI8J2Wu6xma4YID2B-_eOBCN5Ct9A1hZZIaq2d96h4P4wSbIXY44HJa5wOh',
    aspectRatio: 0.8,
  ),
  InspirationItem(
    title: 'Foundry & Bean',
    category: 'Industrial',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuB5vD51uWiFE5Q3DMaJIzKTwCA9Gq6e0EkIRNGQ6FFYu7PDpwZKCaV-i1_eFjClJy0sPZ2JFjS1udNliKtgC1Mms-iPF1693XMoTK4d_oUpDOhRrudW8VogA8ZKyH5EMDUjizCvY5wCh8lNy6tLUcVZ9rVt-Yj6GIgYRfGZw-P2Vx-eWjeg1ta2goPDmwfVMhem_GTtXAmAF9NB-ap0I_8ZsbmGAExKXWNAyhcQjUi3Fkcz9_MPt13fj_XIwNo4YYNURHhVubz_-q8w',
    aspectRatio: 1.0,
  ),
  InspirationItem(
    title: 'Kyoto Shadow Studio',
    category: 'Modern Japanese',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBy6gk5oyc7-nlviqJtvU7HOipIF1msCHVAbLdKy5sYwfitsvD1csZK-MxpJw2u5S_ZvtyU60nu5opd1j8edl5ra8zelid6CGyvw2R9S9437t56wAdO8OI5SJwfYicmBpkJ3x_CT0gK0ZzpTteOgZF9XtSVj26pPchZFSXfuyvsWOzGRDun660AL2E5VxKjJwzJUBmOKzW48yqX6F_VmNbu5XzzbcLc6GdmofJTQdmAdb94nIpjzoAusZwCJqtIyuLZdaBX4uA5QoN6',
    aspectRatio: 0.75,
  ),
  InspirationItem(
    title: 'Heritage Lounge',
    category: 'Vintage',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBsc5y_BikkuzEIsEksI8mRXQW18RrIf8syqCwHnnIfcMYZU4A58dAGvR0rCzw4_f8PBRJW1kZox1UlU5FglVW5m5tzmlZYjp7wG79qo6Uud4BtxCgu_IGFxIW2vygj5f-osIfjOZLBQO_ffBIF132eL_GwpXnrUTYExMj9iSbCHkRW1LhJ0CmMAwiqNHERBmqgJliqitvus06YfYxgwSPBS0Qs6gMj69AXq4NuF5zLDrUUxPAnb5yyYvcQ5zfIvF_ZxQ9kdtAI5wLt',
    aspectRatio: 1.33,
  ),
  InspirationItem(
    title: 'The Monolith Bar',
    category: 'Minimalist',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuADBueeISuOAXEdbr8HlelllInAf-T7mWcLVyFtJhP7vBKsQnimgp44rHnmItL9825InSvUOkfZegid6WmYMlRYvinZDLjG1VFN46UEDd4IBS9wzuIW4xlnCg2QwCVmASZFkoVMdDGyBT5zY7YdETDjjA4gzlBz3u_dTC2QZQN0OK9pEMhYJiVApbswV62_XKfQnwm_uyAispfePtQj5e4TWmP6iKp6hTe_DcX6oKCAG6VnRXSCJIKPrriUZJQMX5SHoLID0vUpPWBz',
    aspectRatio: 1.0,
  ),
  InspirationItem(
    title: 'Mist & Wood',
    category: 'Japandi',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBlNH5NWjKZmhYw5yMgMLQEdbu8CGxJNI1GYV1Q_F431PrPYsnIJMKWx5vexV7My8Iv8etJq_t3r8iGTu3TYlYj0mPtB65-GfqbQ-WIHPKXGtYb2lHyBtRh1Emeo-bvlynsJI6Qm938DTZlehF03nRu8y-zKewlrg2uEC_4SJVv3zmjVJK5-t_DtvYoYaSDl_HkkoDchCAhfnJUQOtozlpt7SrZykdcgpJQFw0uoxTyUlKDvgQfaQNZeqy4plUPMlU8yF0xcSUO3igW',
    aspectRatio: 0.8,
  ),
];
