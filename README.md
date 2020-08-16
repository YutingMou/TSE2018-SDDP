# TSE2018-SDDP
Model for paper on IEEE transactions on sustainable energy: 

Anthony Papavasiliou, Yuting Mou, Léopold Cambier, and Damien Scieur. "_Application of stochastic dual dynamic programming to the real-time dispatch of storage under renewable supply uncertainty_." IEEE Transactions on Sustainable Energy 9, no. 2 (2018): 547-558.

This model is implemented in **Matlab 2016a** and the **SDDP toolbox** needs to be used, which is available here (note the version): https://github.com/leopoldcambier/FAST/tree/0.9.1b

1. **data**: contains data of german power system data, which is collectd from the Internet by Dr. Ignacio Aravena Solís (https://sites.google.com/site/iaravenasolis/home). Many thanks to dear Ignacio.

2. **model**: models of different policies: SDDP, merit order (MO), perfect foresignt (WS) and look ahead. Each of the model is selfcontained, including three files (ProjectXX.m, which is the main file and nldsXX.m and ErrorDisturbance.m)

SDDP takes several hours to compile the lattice and run to convergence, you are recommended to reduce the number of nodes and horizon for an intial test. When doing that, change  following functions in the ProjectXX.m file.
```matlab
  waitAndSee(latticeComplied,myPath(i,1:H) ,params) ;
  forwardPass(lattice,myPath(i,1:H) ,params) ;
```
into
```matlab
  waitAndSee(latticeComplied, 'random', params) ;
  forwardPass(lattice, 'random', params) ;
```
If you have question regarding this model, please feel free to contact me at yuting.mou@outlook.com. The contact information on my personal website is always up-to-date: https://sites.google.com/site/yutingmouchina/home.
