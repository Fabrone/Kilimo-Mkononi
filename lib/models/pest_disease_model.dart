import 'package:cloud_firestore/cloud_firestore.dart';

class PestData {
  final String name;
  final String imagePath;
  final List<String> preventionStrategies;
  final String activeAgent;
  final List<String> possibleCauses;
  final List<String> herbicides;

  PestData({
    required this.name,
    required this.imagePath,
    required this.preventionStrategies,
    required this.activeAgent,
    required this.possibleCauses,
    required this.herbicides,
  });

  static final Map<String, PestData> pestLibrary = {
    // Termites
    'Termites': PestData(
      name: 'Termites',
      imagePath: 'assets/pests/termites.jpg',
      preventionStrategies: ['Crop rotation', 'Use of resistant varieties'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Moist soil', 'Organic debris'],
      herbicides: ['Termidor (Fipronil)', 'Premise (Imidacloprid)'],
    ),
    // Commentary: Accurate. Imidacloprid is a common systemic insecticide for termites, and Termidor/ Premise are widely used products.

    // Cutworms
    'Cutworms': PestData(
      name: 'Cutworms',
      imagePath: 'assets/pests/cutworms.jpg',
      preventionStrategies: ['Remove weeds', 'Ploughing before planting'],
      activeAgent: 'Lambda-cyhalothrin',
      possibleCauses: ['High humidity', 'Weedy fields'],
      herbicides: ['Karate (Lambda-cyhalothrin)', 'Sevin (Carbaryl)'],
    ),
    // Commentary: Accurate. Lambda-cyhalothrin targets cutworms effectively, and Karate/Sevin are recognized products.

    // Maize Shoot Fly
    'Maize Shoot Fly': PestData(
      name: 'Maize Shoot Fly',
      imagePath: 'assets/pests/maize_shoot_fly.jpg',
      preventionStrategies: ['Early planting', 'Use traps'],
      activeAgent: 'Cypermethrin',
      possibleCauses: ['Late planting', 'Warm weather'],
      herbicides: ['Decis (Deltamethrin)', 'Fastac (Cypermethrin)'],
    ),
    // Commentary: Accurate. Cypermethrin is effective against flies, and early planting is a known strategy. Decis/Fastac are suitable products.

    // Aphids
    'Aphids': PestData(
      name: 'Aphids',
      imagePath: 'assets/pests/aphids.jpg',
      preventionStrategies: ['Introduce ladybugs', 'Regular monitoring'],
      activeAgent: 'Neem oil',
      possibleCauses: ['Warm weather', 'Over-fertilization'],
      herbicides: ['Azadirachtin (Neem-based)', 'Admire (Imidacloprid)'],
    ),
    // Commentary: Accurate. Neem oil is a natural aphid control, and ladybugs are biological predators. Azadirachtin/Admire are correct.

    // Stem Borers
    'Stem Borers': PestData(
      name: 'Stem Borers',
      imagePath: 'assets/pests/stem_borers.jpg',
      preventionStrategies: ['Crop residue destruction', 'Plant resistant hybrids'],
      activeAgent: 'Chlorpyrifos',
      possibleCauses: ['Crop residue buildup', 'Warm climates'],
      herbicides: ['Lorsban (Chlorpyrifos)', 'Dursban (Chlorpyrifos)'],
    ),
    // Commentary: Accurate. Chlorpyrifos is widely used for stem borers in maize, and residue management is key. Lorsban/Dursban are common brands.

    // Armyworms
    'Armyworms': PestData(
      name: 'Armyworms',
      imagePath: 'assets/pests/armyworm.jpg',
      preventionStrategies: ['Monitor fields', 'Remove weeds'],
      activeAgent: 'Spinosad',
      possibleCauses: ['Rainy seasons', 'Dense vegetation'],
      herbicides: ['Tracer (Spinosad)', 'Success (Spinosad)'],
    ),
    // Commentary: Accurate. Spinosad is effective against armyworms, and monitoring is a standard practice. Tracer/Success are appropriate products.

    // Leafhoppers
    'Leafhoppers': PestData(
      name: 'Leafhoppers',
      imagePath: 'assets/pests/leaf_hoppers.jpg',
      preventionStrategies: ['Use reflective mulches', 'Control weeds'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Warm weather', 'Nearby host plants'],
      herbicides: ['Confidor (Imidacloprid)', 'Gaucho (Imidacloprid)'],
    ),
    // Commentary: Accurate. Imidacloprid targets leafhoppers, and reflective mulches deter them. Confidor/Gaucho are valid options.

    // Grasshoppers
    'Grasshoppers': PestData(
      name: 'Grasshoppers',
      imagePath: 'assets/pests/grasshopper.jpg',
      preventionStrategies: ['Tillage', 'Natural predators (birds)'],
      activeAgent: 'Malathion',
      possibleCauses: ['Dry weather', 'Overgrazed pastures'],
      herbicides: ['Malathion 57 (Malathion)', 'Fyfanon (Malathion)'],
    ),
    // Commentary: Close to accurate. Malathion is a broad-spectrum insecticide for grasshoppers, though tillage effectiveness varies. Brands are correct.

    // Earworms
    'Earworms': PestData(
      name: 'Earworms',
      imagePath: 'assets/pests/earworm.jpg',
      preventionStrategies: ['Plant early', 'Use traps'],
      activeAgent: 'Carbaryl',
      possibleCauses: ['Warm temperatures', 'Late planting'],
      herbicides: ['Sevin (Carbaryl)', 'Adios (Carbaryl)'],
    ),
    // Commentary: Accurate. Carbaryl controls earworms (e.g., corn earworm), and early planting helps. Sevin/Adios are suitable.

    // Thrips
    'Thrips': PestData(
      name: 'Thrips',
      imagePath: 'assets/pests/thrip.jpg',
      preventionStrategies: ['Use blue sticky traps', 'Crop rotation'],
      activeAgent: 'Spinosad',
      possibleCauses: ['Dry conditions', 'Dense planting'],
      herbicides: ['Entrust (Spinosad)', 'Radiant (Spinosad)'],
    ),
    // Commentary: Accurate. Spinosad is effective against thrips, and sticky traps are a common strategy. Entrust/Radiant are correct.

    // Weevils
    'Weevils': PestData(
      name: 'Weevils',
      imagePath: 'assets/pests/weevil.jpg',
      preventionStrategies: ['Sanitation', 'Dry storage'],
      activeAgent: 'Phosphine',
      possibleCauses: ['Infested seeds', 'Humid storage'],
      herbicides: ['Fumitoxin (Phosphine)', 'Phostoxin (Phosphine)'],
    ),
    // Commentary: Close to accurate. Phosphine is used for stored grain pests like weevils, though typically as a fumigant. Fumitoxin/Phostoxin are correct.

    // Birds
    'Birds': PestData(
      name: 'Birds',
      imagePath: 'assets/pests/birds.jpg',
      preventionStrategies: ['Netting', 'Scare devices (e.g., reflective tape)'],
      activeAgent: 'None (Physical control)',
      possibleCauses: ['Ripening maize', 'Lack of deterrents'],
      herbicides: ['None (Use netting or scarecrows)'],
    ),
    // Commentary: Accurate. Birds require physical deterrents rather than chemical agents; no herbicides apply.

    // Maize Weevil
    'Maize Weevil': PestData(
      name: 'Maize Weevil',
      imagePath: 'assets/pests/maize_weevil.jpg',
      preventionStrategies: ['Dry grain storage', 'Clean silos'],
      activeAgent: 'Phosphine',
      possibleCauses: ['Poor storage hygiene', 'High moisture'],
      herbicides: ['Fumitoxin (Phosphine)', 'Phostoxin (Phosphine)'],
    ),
    // Commentary: Accurate. Maize weevils are storage pests controlled with phosphine fumigation. Brands are correct.

    // Larger Grain Borer
    'Larger Grain Borer': PestData(
      name: 'Larger Grain Borer',
      imagePath: 'assets/pests/larger_grain_borer.jpg',
      preventionStrategies: ['Proper drying', 'Frequent inspection'],
      activeAgent: 'Phosphine',
      possibleCauses: ['Infested grain', 'Warm storage'],
      herbicides: ['Fumitoxin (Phosphine)', 'Phostoxin (Phosphine)'],
    ),
    // Commentary: Accurate. Similar to maize weevil, phosphine is standard for larger grain borers in storage.

    // Angoumois Grain Moth
    'Angoumois Grain Moth': PestData(
      name: 'Angoumois Grain Moth',
      imagePath: 'assets/pests/angoumois_grain_moth.jpg',
      preventionStrategies: ['Seal storage', 'Reduce moisture'],
      activeAgent: 'Phosphine',
      possibleCauses: ['Humid conditions', 'Unsealed grain'],
      herbicides: ['Fumitoxin (Phosphine)', 'Phostoxin (Phosphine)'],
    ),
    // Commentary: Accurate. Phosphine controls storage moths like this, and sealing is key. Brands are appropriate.

    // Rodents
    'Rodents': PestData(
      name: 'Rodents',
      imagePath: 'assets/pests/rodents.jpg',
      preventionStrategies: ['Traps', 'Secure storage'],
      activeAgent: 'Brodifacoum',
      possibleCauses: ['Food availability', 'Poor storage security'],
      herbicides: ['Ratoxin (Brodifacoum)', 'Tomcat (Bromadiolone)'],
    ),
    // Commentary: Close to accurate. Brodifacoum is a common rodenticide, though "herbicides" is a misnomer (should be rodenticides). Ratoxin/Tomcat are examples.

// Bean Fly
    'Bean Fly': PestData(
      name: 'Bean Fly',
      imagePath: 'assets/pests/bean_fly.jpg',
      preventionStrategies: ['Early planting', 'Use resistant varieties'],
      activeAgent: 'Dimethoate',
      possibleCauses: ['Warm weather', 'Late sowing'],
      herbicides: ['Rogor (Dimethoate)', 'Perfekthion (Dimethoate)'],
    ),
    // Commentary: Accurate. Dimethoate is commonly used against bean flies, and early planting reduces infestation. Rogor/Perfekthion are recognized products.

    // Bean Weevil
    'Bean Weevil': PestData(
      name: 'Bean Weevil',
      imagePath: 'assets/pests/bean_weevil.jpg',
      preventionStrategies: ['Dry storage', 'Clean bins'],
      activeAgent: 'Phosphine',
      possibleCauses: ['Infested seeds', 'High humidity'],
      herbicides: ['Fumitoxin (Phosphine)', 'Phostoxin (Phosphine)'],
    ),
    // Commentary: Accurate. Phosphine is standard for stored grain pests like bean weevils. Fumitoxin/Phostoxin are correct fumigants.

    // Beet Armyworms
    'Beet Armyworms': PestData(
      name: 'Beet Armyworms',
      imagePath: 'assets/pests/beet_armyworms.jpg',
      preventionStrategies: ['Monitor fields', 'Remove crop residues'],
      activeAgent: 'Spinosad',
      possibleCauses: ['Warm weather', 'Dense vegetation'],
      herbicides: ['Tracer (Spinosad)', 'Success (Spinosad)'],
    ),
    // Commentary: Accurate. Spinosad effectively controls beet armyworms, and monitoring is key. Tracer/Success are appropriate products.

    // Beetles (Generalized; assuming common bean beetles like Mexican Bean Beetle)
    'Beetles': PestData(
      name: 'Beetles',
      imagePath: 'assets/pests/beetles.jpg',
      preventionStrategies: ['Crop rotation', 'Hand-picking'],
      activeAgent: 'Pyrethrins',
      possibleCauses: ['Warm conditions', 'Nearby host plants'],
      herbicides: ['PyGanic (Pyrethrins)', 'EverGreen (Pyrethrins)'],
    ),
    // Commentary: Close to accurate. Pyrethrins target beetles like the Mexican bean beetle. Specific beetle type isn’t specified, so this is generalized.

    // Bollworms
    'Bollworms': PestData(
      name: 'Bollworms',
      imagePath: 'assets/pests/bollworms.jpg',
      preventionStrategies: ['Use pheromone traps', 'Remove affected fruits'],
      activeAgent: 'Spinosad',
      possibleCauses: ['Warm weather', 'Fruiting stage'],
      herbicides: ['Entrust (Spinosad)', 'Success (Spinosad)'],
    ),
    // Commentary: Accurate. Spinosad is effective against bollworms (e.g., cotton bollworm, also affects tomatoes/potatoes). Entrust/Success are suitable products.

    // Bruchid Beetles
    'Bruchid Beetles': PestData(
      name: 'Bruchid Beetles',
      imagePath: 'assets/pests/bruchid_beetles.jpg',
      preventionStrategies: ['Dry seeds', 'Cold storage'],
      activeAgent: 'Phosphine',
      possibleCauses: ['Infested legumes', 'Poor storage'],
      herbicides: ['Fumitoxin (Phosphine)', 'Phostoxin (Phosphine)'],
    ),
    // Commentary: Accurate. Phosphine is used for bruchid beetles in stored beans. Fumitoxin/Phostoxin are standard.

    // Cabbage Looper
    'Cabbage Looper': PestData(
      name: 'Cabbage Looper',
      imagePath: 'assets/pests/cabbage_looper.jpg',
      preventionStrategies: ['Row covers', 'Biological control (e.g., Trichogramma)'],
      activeAgent: 'Bacillus thuringiensis (Bt)',
      possibleCauses: ['Warm nights', 'Leafy crops'],
      herbicides: ['Dipel (Bt)', 'Thuricide (Bt)'],
    ),
    // Commentary: Accurate. Bt is a specific control for caterpillars like cabbage loopers. Dipel/Thuricide are widely used.

    // Cabbage Root Maggot
    'Cabbage Root Maggot': PestData(
      name: 'Cabbage Root Maggot',
      imagePath: 'assets/pests/cabbage_root_maggot.jpg',
      preventionStrategies: ['Crop rotation', 'Floating row covers'],
      activeAgent: 'Chlorpyrifos',
      possibleCauses: ['Cool, wet soil', 'Previous brassica crops'],
      herbicides: ['Lorsban (Chlorpyrifos)', 'Dursban (Chlorpyrifos)'],
    ),
    // Commentary: Accurate. Chlorpyrifos targets root maggots, and row covers prevent egg-laying. Lorsban/Dursban are correct.

    // Cabbage Webworm
    'Cabbage Webworm': PestData(
      name: 'Cabbage Webworm',
      imagePath: 'assets/pests/cabbage_webworm.jpg',
      preventionStrategies: ['Remove plant debris', 'Monitor seedlings'],
      activeAgent: 'Spinosad',
      possibleCauses: ['Warm weather', 'Unclean fields'],
      herbicides: ['Entrust (Spinosad)', 'Radiant (Spinosad)'],
    ),
    // Commentary: Accurate. Spinosad controls webworms effectively. Entrust/Radiant are suitable products.

    // Carrot Rust Fly
    'Carrot Rust Fly': PestData(
      name: 'Carrot Rust Fly',
      imagePath: 'assets/pests/carrot_rust_fly.jpg',
      preventionStrategies: ['Crop rotation', 'Row covers'],
      activeAgent: 'Spinosad',
      possibleCauses: ['Cool, moist conditions', 'Carrot fields'],
      herbicides: ['Entrust (Spinosad)', 'Success (Spinosad)'],
    ),
    // Commentary: Close to accurate. Spinosad is effective against flies; row covers are standard. Entrust/Success are appropriate.

    // Carrot Weevil
    'Carrot Weevil': PestData(
      name: 'Carrot Weevil',
      imagePath: 'assets/pests/carrot_weevil.jpg',
      preventionStrategies: ['Crop rotation', 'Remove crop residue'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Previous carrot crops', 'Warm soil'],
      herbicides: ['Admire (Imidacloprid)', 'Confidor (Imidacloprid)'],
    ),
    // Commentary: Accurate. Imidacloprid targets weevils, and rotation helps. Admire/Confidor are correct.

    // Caseworms
    'Caseworms': PestData(
      name: 'Caseworms',
      imagePath: 'assets/pests/caseworms.jpg',
      preventionStrategies: ['Drain fields periodically', 'Use resistant varieties'],
      activeAgent: 'Chlorpyrifos',
      possibleCauses: ['Flooded fields', 'Warm weather'],
      herbicides: ['Lorsban (Chlorpyrifos)', 'Dursban (Chlorpyrifos)'],
    ),
    // Commentary: Accurate. Chlorpyrifos controls caseworms in rice paddies. Lorsban/Dursban are standard.

    // Cassava Green Mite
    'Cassava Green Mite': PestData(
      name: 'Cassava Green Mite',
      imagePath: 'assets/pests/cassava_green_mite.jpg',
      preventionStrategies: ['Plant resistant varieties', 'Maintain humidity'],
      activeAgent: 'Abamectin',
      possibleCauses: ['Dry conditions', 'Poor plant health'],
      herbicides: ['Agri-Mek (Abamectin)', 'Avid (Abamectin)'],
    ),
    // Commentary: Accurate. Abamectin is effective against mites, and dry conditions favor cassava green mites. Agri-Mek/Avid are correct.

    // Cassava Mosaic Virus Vectors
    'Cassava Mosaic Virus Vectors': PestData(
      name: 'Cassava Mosaic Virus Vectors',
      imagePath: 'assets/pests/cassava_mosaic_virus_vectors.jpg',
      preventionStrategies: ['Remove infected plants', 'Control whiteflies'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Whitefly populations', 'Warm climates'],
      herbicides: ['Admire (Imidacloprid)', 'Confidor (Imidacloprid)'],
    ),
    // Commentary: Accurate. Imidacloprid targets whiteflies (primary vectors). Admire/Confidor are suitable.

    // Colorado Potato Beetle
    'Colorado Potato Beetle': PestData(
      name: 'Colorado Potato Beetle',
      imagePath: 'assets/pests/colorado_potato_beetle.jpg',
      preventionStrategies: ['Crop rotation', 'Hand-picking'],
      activeAgent: 'Spinosad',
      possibleCauses: ['Potato monoculture', 'Warm weather'],
      herbicides: ['Entrust (Spinosad)', 'Radiant (Spinosad)'],
    ),
    // Commentary: Accurate. Spinosad is effective and less resistance-prone than older chemicals. Entrust/Radiant are correct.

    // Diamondback Moth
    'Diamondback Moth': PestData(
      name: 'Diamondback Moth',
      imagePath: 'assets/pests/diamondback_moth.jpg',
      preventionStrategies: ['Use pheromone traps', 'Crop rotation'],
      activeAgent: 'Bacillus thuringiensis (Bt)',
      possibleCauses: ['Warm weather', 'Brassica crops'],
      herbicides: ['Dipel (Bt)', 'Thuricide (Bt)'],
    ),
    // Commentary: Accurate. Bt is specific to caterpillars like diamondback moths. Dipel/Thuricide are standard.

    // Ear-Cutting Caterpillars
    'Ear-Cutting Caterpillars': PestData(
      name: 'Ear-Cutting Caterpillars',
      imagePath: 'assets/pests/ear_cutting_caterpillars.jpg',
      preventionStrategies: ['Monitor rice ears', 'Remove weeds'],
      activeAgent: 'Cypermethrin',
      possibleCauses: ['Late-season growth', 'High humidity'],
      herbicides: ['Fastac (Cypermethrin)', 'Decis (Deltamethrin)'],
    ),
    // Commentary: Close to accurate. Cypermethrin targets caterpillars in rice; specific data is limited, but this is reasonable. Fastac/Decis are suitable.

    // Flea Beetles
    'Flea Beetles': PestData(
      name: 'Flea Beetles',
      imagePath: 'assets/pests/flea_beetles.jpg',
      preventionStrategies: ['Row covers', 'Crop rotation'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Warm, dry weather', 'Young plants'],
      herbicides: ['Admire (Imidacloprid)', 'Gaucho (Imidacloprid)'],
    ),
    // Commentary: Accurate. Imidacloprid controls flea beetles effectively. Admire/Gaucho are common products.

    // Fruit Borers
    'Fruit Borers': PestData(
      name: 'Fruit Borers',
      imagePath: 'assets/pests/fruit_borers.jpg',
      preventionStrategies: ['Remove infested fruits', 'Use traps'],
      activeAgent: 'Spinosad',
      possibleCauses: ['Warm weather', 'Ripening fruits'],
      herbicides: ['Entrust (Spinosad)', 'Success (Spinosad)'],
    ),
    // Commentary: Accurate. Spinosad targets fruit borers (e.g., tomato fruit borer). Entrust/Success are appropriate.

    // Fruit Flies
    'Fruit Flies': PestData(
      name: 'Fruit Flies',
      imagePath: 'assets/pests/fruit_flies.jpg',
      preventionStrategies: ['Sanitation', 'Use bait traps'],
      activeAgent: 'Spinosad',
      possibleCauses: ['Overripe fruit', 'Warm weather'],
      herbicides: ['GF-120 (Spinosad)', 'Entrust (Spinosad)'],
    ),
    // Commentary: Accurate. Spinosad is widely used for fruit flies. GF-120 is a bait product; Entrust is foliar.

    // Grain Borers
    'Grain Borers': PestData(
      name: 'Grain Borers',
      imagePath: 'assets/pests/grain_borers.jpg',
      preventionStrategies: ['Dry storage', 'Clean bins'],
      activeAgent: 'Phosphine',
      possibleCauses: ['Infested grain', 'High moisture'],
      herbicides: ['Fumitoxin (Phosphine)', 'Phostoxin (Phosphine)'],
    ),
    // Commentary: Accurate. Phosphine is standard for grain borers in storage. Fumitoxin/Phostoxin are correct.

    // Grain-Feeding Weevils
    'Grain-Feeding Weevils': PestData(
      name: 'Grain-Feeding Weevils',
      imagePath: 'assets/pests/grain_feeding_weevils.jpg',
      preventionStrategies: ['Proper drying', 'Sanitation'],
      activeAgent: 'Phosphine',
      possibleCauses: ['Humid storage', 'Infested grain'],
      herbicides: ['Fumitoxin (Phosphine)', 'Phostoxin (Phosphine)'],
    ),
    // Commentary: Accurate. Similar to other storage weevils; phosphine is appropriate. Fumitoxin/Phostoxin are standard.

    // Hessian Fly
    'Hessian Fly': PestData(
      name: 'Hessian Fly',
      imagePath: 'assets/pests/hessian_fly.jpg',
      preventionStrategies: ['Late planting', 'Resistant varieties'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Early sowing', 'Wheat fields'],
      herbicides: ['Gaucho (Imidacloprid)', 'Confidor (Imidacloprid)'],
    ),
    // Commentary: Accurate. Imidacloprid controls hessian flies in wheat. Gaucho/Confidor are suitable.

    // Leafminers
    'Leafminers': PestData(
      name: 'Leafminers',
      imagePath: 'assets/pests/leafminers.jpg',
      preventionStrategies: ['Remove affected leaves', 'Use sticky traps'],
      activeAgent: 'Abamectin',
      possibleCauses: ['Warm weather', 'Leafy crops'],
      herbicides: ['Agri-Mek (Abamectin)', 'Avid (Abamectin)'],
    ),
    // Commentary: Accurate. Abamectin targets leafminers effectively. Agri-Mek/Avid are common products.

    // Mealybugs
    'Mealybugs': PestData(
      name: 'Mealybugs',
      imagePath: 'assets/pests/mealybugs.jpg',
      preventionStrategies: ['Prune infested parts', 'Introduce predators (e.g., ladybugs)'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Warm, humid conditions', 'Overcrowded plants'],
      herbicides: ['Admire (Imidacloprid)', 'Confidor (Imidacloprid)'],
    ),
    // Commentary: Accurate. Imidacloprid controls mealybugs; biological control is also effective. Admire/Confidor are correct.

    // Nematodes
    'Nematodes': PestData(
      name: 'Nematodes',
      imagePath: 'assets/pests/nematodes.jpg',
      preventionStrategies: ['Crop rotation', 'Soil solarization'],
      activeAgent: 'Oxamyl',
      possibleCauses: ['Infested soil', 'Continuous cropping'],
      herbicides: ['Vydate (Oxamyl)', 'Nemacur (Fenamiphos)'],
    ),
    // Commentary: Accurate. Oxamyl is a nematicide; rotation and solarization are standard. Vydate/Nemacur are appropriate.

    // Plant Hoppers
    'Plant Hoppers': PestData(
      name: 'Plant Hoppers',
      imagePath: 'assets/pests/plant_hoppers.jpg',
      preventionStrategies: ['Control weeds', 'Use resistant varieties'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Warm, wet conditions', 'Rice paddies'],
      herbicides: ['Admire (Imidacloprid)', 'Confidor (Imidacloprid)'],
    ),
    // Commentary: Accurate. Imidacloprid targets plant hoppers in rice. Admire/Confidor are suitable.

    // Pod Borers
    'Pod Borers': PestData(
      name: 'Pod Borers',
      imagePath: 'assets/pests/pod_borers.jpg',
      preventionStrategies: ['Remove infested pods', 'Use traps'],
      activeAgent: 'Spinosad',
      possibleCauses: ['Warm weather', 'Late planting'],
      herbicides: ['Entrust (Spinosad)', 'Success (Spinosad)'],
    ),
    // Commentary: Accurate. Spinosad controls pod borers (e.g., in beans). Entrust/Success are correct.

    // Potato Tuber Moth
    'Potato Tuber Moth': PestData(
      name: 'Potato Tuber Moth',
      imagePath: 'assets/pests/potato_tuber_moth.jpg',
      preventionStrategies: ['Cover tubers with soil', 'Harvest early'],
      activeAgent: 'Chlorpyrifos',
      possibleCauses: ['Exposed tubers', 'Warm storage'],
      herbicides: ['Lorsban (Chlorpyrifos)', 'Dursban (Chlorpyrifos)'],
    ),
    // Commentary: Accurate. Chlorpyrifos targets tuber moths; covering tubers is key. Lorsban/Dursban are standard.

    // Rice Bug
    'Rice Bug': PestData(
      name: 'Rice Bug',
      imagePath: 'assets/pests/rice_bug.jpg',
      preventionStrategies: ['Remove weeds', 'Synchronize planting'],
      activeAgent: 'Cypermethrin',
      possibleCauses: ['Ripening grains', 'Warm weather'],
      herbicides: ['Fastac (Cypermethrin)', 'Decis (Deltamethrin)'],
    ),
    // Commentary: Accurate. Cypermethrin controls rice bugs (e.g., stink bugs); weed control helps. Fastac/Decis are appropriate.

    // Rice Gall Midges
    'Rice Gall Midges': PestData(
      name: 'Rice Gall Midges',
      imagePath: 'assets/pests/rice_gall_midges.jpg',
      preventionStrategies: ['Destroy infested shoots', 'Avoid excessive nitrogen'],
      activeAgent: 'Dimethoate',
      possibleCauses: ['Wet conditions', 'Young plants'],
      herbicides: ['Rogor (Dimethoate)', 'Perfekthion (Dimethoate)'],
    ),
    // Commentary: Accurate. Dimethoate targets gall midges in rice; shoot removal is standard. Rogor/Perfekthion are correct.

    // Rice Hispa
    'Rice Hispa': PestData(
      name: 'Rice Hispa',
      imagePath: 'assets/pests/rice_hispa.jpg',
      preventionStrategies: ['Remove weeds', 'Clip affected leaves'],
      activeAgent: 'Chlorpyrifos',
      possibleCauses: ['Humid conditions', 'Dense foliage'],
      herbicides: ['Lorsban (Chlorpyrifos)', 'Dursban (Chlorpyrifos)'],
    ),
    // Commentary: Accurate. Chlorpyrifos controls rice hispa beetles; leaf clipping is effective. Lorsban/Dursban are suitable.

    // Rice Root Weevils
    'Rice Root Weevils': PestData(
      name: 'Rice Root Weevils',
      imagePath: 'assets/pests/rice_root_weevils.jpg',
      preventionStrategies: ['Drain fields', 'Crop rotation'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Flooded fields', 'Warm soil'],
      herbicides: ['Admire (Imidacloprid)', 'Confidor (Imidacloprid)'],
    ),
    // Commentary: Close to accurate. Imidacloprid targets root weevils; draining reduces larvae survival. Admire/Confidor are appropriate.

    // Scale Insects
    'Scale Insects': PestData(
      name: 'Scale Insects',
      imagePath: 'assets/pests/scale_insects.jpg',
      preventionStrategies: ['Prune infested parts', 'Introduce predators (e.g., ladybugs)'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Warm, dry conditions', 'Stressed plants'],
      herbicides: ['Admire (Imidacloprid)', 'Confidor (Imidacloprid)'],
    ),
    // Commentary: Accurate. Imidacloprid controls scale insects; pruning is effective. Admire/Confidor are correct.

    // Spider Mites
    'Spider Mites': PestData(
      name: 'Spider Mites',
      imagePath: 'assets/pests/spider_mites.jpg',
      preventionStrategies: ['Increase humidity', 'Use predatory mites'],
      activeAgent: 'Abamectin',
      possibleCauses: ['Dry conditions', 'Dusty fields'],
      herbicides: ['Agri-Mek (Abamectin)', 'Avid (Abamectin)'],
    ),
    // Commentary: Accurate. Abamectin is a standard miticide; humidity deters mites. Agri-Mek/Avid are suitable.

    // Stink Bugs
    'Stink Bugs': PestData(
      name: 'Stink Bugs',
      imagePath: 'assets/pests/stink_bugs.jpg',
      preventionStrategies: ['Remove weeds', 'Use traps'],
      activeAgent: 'Cypermethrin',
      possibleCauses: ['Warm weather', 'Fruiting crops'],
      herbicides: ['Fastac (Cypermethrin)', 'Decis (Deltamethrin)'],
    ),
    // Commentary: Accurate. Cypermethrin controls stink bugs; weed management helps. Fastac/Decis are appropriate.

    // Storage Weevils
    'Storage Weevils': PestData(
      name: 'Storage Weevils',
      imagePath: 'assets/pests/storage_weevils.jpg',
      preventionStrategies: ['Dry storage', 'Clean facilities'],
      activeAgent: 'Phosphine',
      possibleCauses: ['Moist grain', 'Infested storage'],
      herbicides: ['Fumitoxin (Phosphine)', 'Phostoxin (Phosphine)'],
    ),
    // Commentary: Accurate. Phosphine is standard for storage pests; drying is key. Fumitoxin/Phostoxin are correct.

    // Sugarcane Root Borers
    'Sugarcane Root Borers': PestData(
      name: 'Sugarcane Root Borers',
      imagePath: 'assets/pests/sugarcane_root_borers.jpg',
      preventionStrategies: ['Crop rotation', 'Healthy planting material'],
      activeAgent: 'Chlorpyrifos',
      possibleCauses: ['Infested soil', 'Warm conditions'],
      herbicides: ['Lorsban (Chlorpyrifos)', 'Dursban (Chlorpyrifos)'],
    ),
    // Commentary: Accurate. Chlorpyrifos targets root borers in sugarcane. Lorsban/Dursban are standard.

    // Sugarcane Top Shoot Borers
    'Sugarcane Top Shoot Borers': PestData(
      name: 'Sugarcane Top Shoot Borers',
      imagePath: 'assets/pests/sugarcane_top_shoot_borers.jpg',
      preventionStrategies: ['Remove affected shoots', 'Use resistant varieties'],
      activeAgent: 'Cartap',
      possibleCauses: ['Warm, humid weather', 'Young shoots'],
      herbicides: ['Padan (Cartap)', 'Calcartap (Cartap)'],
    ),
    // Commentary: Accurate. Cartap is specific for top shoot borers in sugarcane; shoot removal is standard. Padan/Calcartap are correct.

    // Tomato Hornworms
    'Tomato Hornworms': PestData(
      name: 'Tomato Hornworms',
      imagePath: 'assets/pests/tomato_hornworms.jpg',
      preventionStrategies: ['Hand-picking', 'Introduce parasitic wasps'],
      activeAgent: 'Bacillus thuringiensis (Bt)',
      possibleCauses: ['Warm nights', 'Tomato crops'],
      herbicides: ['Dipel (Bt)', 'Thuricide (Bt)'],
    ),
    // Commentary: Accurate. Bt targets hornworms specifically; hand-picking is effective. Dipel/Thuricide are suitable.

    // Tomato Leafminers
    'Tomato Leafminers': PestData(
      name: 'Tomato Leafminers',
      imagePath: 'assets/pests/tomato_leafminers.jpg',
      preventionStrategies: ['Remove infested leaves', 'Use yellow traps'],
      activeAgent: 'Abamectin',
      possibleCauses: ['Warm weather', 'Tomato fields'],
      herbicides: ['Agri-Mek (Abamectin)', 'Avid (Abamectin)'],
    ),
    // Commentary: Accurate. Abamectin controls leafminers; leaf removal helps. Agri-Mek/Avid are correct.

    // Wheat Midges
    'Wheat Midges': PestData(
      name: 'Wheat Midges',
      imagePath: 'assets/pests/wheat_midges.jpg',
      preventionStrategies: ['Late planting', 'Resistant varieties'],
      activeAgent: 'Chlorpyrifos',
      possibleCauses: ['Warm, wet springs', 'Flowering wheat'],
      herbicides: ['Lorsban (Chlorpyrifos)', 'Dursban (Chlorpyrifos)'],
    ),
    // Commentary: Accurate. Chlorpyrifos targets wheat midges (e.g., orange wheat blossom midge). Lorsban/Dursban are appropriate.

    // White Grubs
    'White Grubs': PestData(
      name: 'White Grubs',
      imagePath: 'assets/pests/white_grubs.jpg',
      preventionStrategies: ['Deep tillage', 'Crop rotation'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Grassy fields', 'Warm soil'],
      herbicides: ['Admire (Imidacloprid)', 'Confidor (Imidacloprid)'],
    ),
    // Commentary: Accurate. Imidacloprid controls white grubs (e.g., in sugarcane); tillage disrupts larvae. Admire/Confidor are correct.

    // Whiteflies
    'Whiteflies': PestData(
      name: 'Whiteflies',
      imagePath: 'assets/pests/whiteflies.jpg',
      preventionStrategies: ['Use reflective mulches', 'Introduce predators (e.g., Encarsia)'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Warm, humid weather', 'Greenhouse conditions'],
      herbicides: ['Admire (Imidacloprid)', 'Confidor (Imidacloprid)'],
    ),
    // Commentary: Accurate. Imidacloprid is a standard control for whiteflies; mulches and predators are effective. Admire/Confidor are correct.

    // Wireworms
    'Wireworms': PestData(
      name: 'Wireworms',
      imagePath: 'assets/pests/wireworms.jpg',
      preventionStrategies: ['Crop rotation', 'Avoid grassy fields'],
      activeAgent: 'Imidacloprid',
      possibleCauses: ['Cool, moist soil', 'Previous grass crops'],
      herbicides: ['Gaucho (Imidacloprid)', 'Admire (Imidacloprid)'],
    ),
    // Commentary: Accurate. Imidacloprid targets wireworms; rotation reduces populations. Gaucho/Admire are suitable.
  };
}

class PestIntervention {
  final String? id;
  final String pestName;
  final String cropType;
  final String cropStage;
  final String intervention;
  final double? dosage;
  final String? unit;
  final double? area;
  final String areaUnit;
  final Timestamp timestamp;
  final String userId; // Added userId field

  PestIntervention({
    this.id,
    required this.pestName,
    required this.cropType,
    required this.cropStage,
    required this.intervention,
    this.dosage,
    this.unit,
    this.area,
    required this.areaUnit,
    required this.timestamp,
    required this.userId, // Make userId required
  });

  Map<String, dynamic> toMap() => {
        'pestName': pestName,
        'cropType': cropType,
        'cropStage': cropStage,
        'intervention': intervention,
        'dosage': dosage,
        'unit': unit,
        'area': area,
        'areaUnit': areaUnit,
        'timestamp': timestamp,
        'userId': userId, // Include userId in the map
      };

  factory PestIntervention.fromMap(Map<String, dynamic> map, String id) => PestIntervention(
        id: id,
        pestName: map['pestName'] as String,
        cropType: map['cropType'] as String,
        cropStage: map['cropStage'] as String,
        intervention: map['intervention'] as String,
        dosage: map['dosage'] as double?,
        unit: map['unit'] as String?,
        area: map['area'] as double?,
        areaUnit: map['areaUnit'] as String,
        timestamp: map['timestamp'] as Timestamp,
        userId: map['userId'] as String,
      );

  PestIntervention copyWith({
    String? id,
    String? pestName,
    String? cropType,
    String? cropStage,
    String? intervention,
    double? dosage,
    String? unit,
    double? area,
    String? areaUnit,
    Timestamp? timestamp,
    String? userId,
  }) => PestIntervention(
        id: id ?? this.id,
        pestName: pestName ?? this.pestName,
        cropType: cropType ?? this.cropType,
        cropStage: cropStage ?? this.cropStage,
        intervention: intervention ?? this.intervention,
        dosage: dosage ?? this.dosage,
        unit: unit ?? this.unit,
        area: area ?? this.area,
        areaUnit: areaUnit ?? this.areaUnit,
        timestamp: timestamp ?? this.timestamp,
        userId: userId ?? this.userId,
      );
}