data:extend({
    {
        type = "technology",
        name = "shuttleTrain_tech",
        icon = "__ShuttleTrain__/graphics/icon_shuttleTrain_tech.png",
        icon_size = 128,
        effects = 
        {
            {
                type = "unlock-recipe",
                recipe = "shuttleTrain"
            }
        },    
        prerequisites = {"automated-rail-transportation"},
        unit =
        {
          count = 70,
          ingredients =
          {
            {"science-pack-1", 2},
            {"science-pack-2", 1},
          },
          time = 20
        },
        order = "c-g-b-a"
    },
})