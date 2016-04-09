data:extend({
    {
        type = "technology",
        name = "shuttleTrain_tech",
        icon = "__ShuttleTrain__/graphics/icon_shuttleTrain_tech.png",
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
        }
    },
})