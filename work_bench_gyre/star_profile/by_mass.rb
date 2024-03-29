load 'load.rb'

model = -1 # -1 means the most recent profile
log_dir = '../LOGS'

pp = ProfilePlots.new(
    'xaxis_by' => 'mass',
    'model' => model,   
    'log_dir' => log_dir,
    'log_mass_frac_ymin' => -6, 
    'log_mass_frac_ymax' => nil,
    #'xmin' => nil, 'xmax' => nil)
    'xmin' => 0.6, 'xmax' => 0.7)
   
#load 'extras.rb'
#pp.add_extras
  