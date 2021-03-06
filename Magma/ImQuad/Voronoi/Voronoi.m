import "../../BasicData.m": n,d,steinitz;
import "../../Initialize.m": K,w,tau,p1,p2,ZB,B,BasHermNorm,mmax,F,sqrtd,Injec;
import "../Functions/Groups.m": matbas,matbas2,matbas3;



intrinsic VoronoiAlgorithm(: quiet:=false,SL:=false,CheckMembership:=0) -> VData
 {ImQuad: Voronoi algorithm. If SL is set everything will be done with respect to the special linear group instead of GL}
 //Find a first perfect form

 Pini:=NewHermForm(MatrixRing(K,n)!1);
 
 Pinie:=TraceForm(Pini);
 Pinie2:=TraceForm(NewHermForm(w*Pini`Matrix));
 Lini:=LatticeWithGram(Pinie);
 Sini:=MinimalVectors(Pini);
 Rini:=PerfectionRank(Pini);

 count:=1;

 while Rini lt n^2 and count lt 100 do
  count:=count+1;
  dir:=FindPerp([HermitianTranspose(x)*x : x in Sini]);
  tsup:=1000;
  tinf:=0;
  t:=(tsup+tinf)/2;
  bool:=false;
  count2:=1;

  while not bool and count2 lt 100 do
   count2:=count2+1;
   M:=1;
   Pt:=NewHermForm(Pini`Matrix+t*dir);
   while M eq 1 do
    if IsPositiveDefinite(TraceForm(Pt)) then
     Lt:=LatticeWithGram(TraceForm(Pt));
     M:=HermitianMinimum(Pt);
     if M eq 1 then
      tinf:=t;
      t:=(tinf+tsup)/2;
      Pt:=NewHermForm(Pini`Matrix+t*dir);
     end if;
    else
     tsup:=t;
     t:=(tinf+tsup)/2;
     Pt:=NewHermForm(Pini`Matrix+t*dir);
    end if;
   end while;
   St:=MinimalVectors(Pt);

   tt:=Rationals()!
      Min([(IdealNorm(v)-K!((v*Pini`Matrix*HermitianTranspose(v))[1,1]))/(K!((v*dir*HermitianTranspose(v))[1,1])) : v in St]);
   bool:=false;
   if tt lt t and tt gt 0 then
    Pc:=NewHermForm(Pini`Matrix+tt*dir);
    Pce:=TraceForm(Pc);
    Lc:=LatticeWithGram(Pce);
    M:=HermitianMinimum(Pc);
    if M eq 1 then
     bool:=true;
    else
     tsup:=tt;
     t:=(tinf+tsup)/2;
     Pt:=NewHermForm(Pini`Matrix+t*dir);
    end if;
   else
    tsup:=t;
    t:=(tsup+tinf)/2;
    Pt:=NewHermForm(Pini`Matrix+t*dir);
   end if;
  end while;

  Pini:=Pc;
  Pinie:=TraceForm(Pini);

  Lini:=LatticeWithGram(Pinie);
  Sini:=MinimalVectors(Pini);
  Rini:=PerfectionRank(Pini);
 end while;

 if Rini ne n^2 then
  error "In FirstPerfect: the form Rini is not perfect.";
 end if;

 //Enumerate perfect neighbours in order to obtain a set of representatives
 //of perfect Hermitian forms

 perfectlist:=[Pini];         //List of representatives of perfect forms
 vectlist:=[**];              //List of shortest vectors of perfect forms
 facelist:=[**];              //List of facets of V-domains of p. forms; given by shortest vectors
 faceneu:=[**];               // 1 at [i][j] if neighbor(facelist[i][j]) >= i
                              // 0 else
 facevectlist:=[**];          //Perpendicular form to shortest vectors defining the respective facet
 Dim2facevectList:=[**];      //
 FaceFormList:=[**];          //List of forms defined by those shortest vectors, which define the respective facet
 AutList:=[**];               //List of Aut-Groups of the inverse FaceForms
 Dim2FormList:=[**];          //
 Dim2FaceList:=[**];          //
 Dim2AutList:=[**];           //

 numberoffaces:=[];           //List of number of faces of V-domains of p. forms
 E:={**};                     //multiset encoding the Voronoi graph of perfect forms
 Todo:=[Pini];                //List of perfect forms to be treated with Voronoi
 minvecss:=[MinimalVectors(Pini)];
 PerfectNeighbourList:=[**];  //List of perfect neighbours of all (mod GL) perfect forms

 CriticalValueList:=[**];     //List of critical rho values (from Voronoi's algorithm)
 FacetVectorList:=[**];       //List of facet vectors (from Voronoi's algorithm)

 FaceTrafoList:=[**];

 NeighbourList:=[**];         //List of numbers of standard representatives of neighbours

 while(#Todo gt 0) do
  P:=Todo[1];
  Pe:=TraceForm(P);
  L:=LatticeWithGram(Pe);
  m:=HermitianMinimum(P);
  Sk:=MinimalVectors(P);
  Sproj:=[SymmetricCoordinates(HermitianTranspose(v)*v) : v in Sk];
  Append(~vectlist,Sk);

  Exclude(~Todo,Todo[1]);
  if not quiet then
   print "Still " cat IntegerToString(#Todo+1) cat " forms to treat. I have found " cat IntegerToString(#perfectlist) cat " perfect forms.";
  end if;

  if PerfectionRankList(Sk) ne n^2 then
   error "In enumerating perfect neighbours: perfection rank of potential neighbour is too small.";
  end if;

  G:=HermitianAutomorphismGroup(P:SL:=SL,CheckMembership:=CheckMembership);
  G:=ChangeRing(G,Rationals());


 Sprojtest:=[HermitianTranspose(v)*v : v in Sk];
  GeneratorsOfPolytope:=[[Rationals()!0 : i in [1..n^2]]];
 
  GeneratorsOfPolytope cat:= [Eltseq(SymmetricCoordinates(X)): X in Sprojtest];
  print "Generators of Polytope constructed.";
  Poly:=Polytope(GeneratorsOfPolytope);
  print "Polytope constructed.";
  Faces:=FaceIndices(Poly,n^2-1);
  print "Faces calculated.";
  Faces:=[Exclude(x,1) : x in Faces | 1 in x];
  Faces:=[{a-1 : a in x} : x in Faces];
  //return Faces;
  P`Vertices:=[ CoordinatesToMatrix(Vector(x)) : x in Vertices(Poly) | x ne Vertices(Poly)[1]]; 
  Append(~numberoffaces,#Faces);
  Append(~facelist,Faces);
  FaceForms:=[];
  AutFF:=[];
  facevect:=[];
  for F in Faces do
   FF:=Parent(Pini`Matrix) ! 0;
   for k in F do
    Fk:= HermitianTranspose(Sk[k])*Sk[k];
    FF := FF+ Fk;
   end for;
   gL:=FindPerp([HermitianTranspose(Sk[k])*Sk[k] : k in F]);
   //if #gL eq 1 then
    Append(~facevect,gL);
   //end if;
  end for;
  Append(~facevectlist,[**]);

  count:=0;
  FFFaces:=Faces;

  
 
  PerfectNeighbours:=[**];    //List of perfect neighbours of P being treated
  Neighbours:=[**];           //List of indices of standard representatives of perf. neighbours of P
  CriticalValues:=[**];       //List of critical rho-values of P
  fneu:=[];
  if not quiet then print "I am now treating a Voronoi domain which has " cat IntegerToString(#Faces) cat " faces."; end if;
  TrafoList:=[**];
  while(#Faces gt 0) do
   count:=count+1;
   
   F1:=FindPerp([HermitianTranspose(Sk[n])*Sk[n] : n in Faces[1]]);
   FF1:=NewHermForm(F1);
   Exclude(~Faces,Faces[1]);
   sgn:=Sign(&+ [Rationals()!EvaluateVector(FF1,x) : x in Sk]);
   F1:=sgn*F1;
   FF1:=NewHermForm(F1);
   Append(~FacetVectorList,FF1);  


   facevectlist[#facevectlist]:=facevectlist[#facevectlist] cat [*F1*];

  

   tsup:=10000;
   tinf:=0;
   t:=(tinf+tsup)/2;
   minimcont:=0;
   while minimcont ne 1 do
    coherent:=false;
    while not coherent do
     Pt:=NewHermForm(P`Matrix+t*F1);
     M:=1;
     while M eq 1 do
      if IsPositiveDefinite(TraceForm(Pt)) then
       M:=HermitianMinimum(Pt);
       if M eq 1 then
        tinf:=t;
        t:=(tinf+tsup)/2;
        Pt:=NewHermForm(P`Matrix+t*F1);
       end if;
      else
       tsup:=t;
       t:=(tinf+tsup)/2;
       Pt:=NewHermForm(P`Matrix+t*F1);
      end if;
     end while;
     St:=MinimalVectors(Pt);
     SFace:=[ s : s in Sk | EvaluateVector(FF1,s) eq 0];
 
     Condlist:=[HermitianTranspose(s)*s : s in SFace] cat [HermitianTranspose(s)*s : s in St];
     Cond:=KMatrixSpace(Rationals(),n^2,#Condlist)!0;
     for i in [1..n^2] do
      for j in [1..#Condlist] do
       Cond[i][j]:=Trace(BasHermNorm[i]*Condlist[j]);
      end for;
     end for;
     Uns:=Vector( #Condlist , [ Rationals()!(IdealNorm(v)) : v in SFace ] cat [Rationals()!(IdealNorm(v)) : v in St] );

 
     coherent:=IsConsistent(Cond,Uns);
     if not coherent then
      tsup:=t;
      t:=(tinf+tsup)/2;
      Pt:=NewHermForm(P`Matrix+t*F1);
     end if;
    end while;
    Pcont:=NewHermForm(CoordinatesToMatrix(Solution(Cond,Uns)));
    Pconte:=TraceForm(Pcont);
    Lcont:=LatticeWithGram(Pconte);
   
    Scontk:=MinimalVectors(Pcont);
 
    minimcont:=HermitianMinimum(Pcont);
 
    tsup:=t;
    t:=(tinf+tsup)/2;
    Pt:=NewHermForm(P`Matrix+t*F1);
   end while;
      if Pcont eq NewHermForm(MatrixRing(K,n)!1) then error "BLA"; end if;
 
   Append(~PerfectNeighbours,Pcont);
 
   //Determine critical value rho:
   C:=Pcont`Matrix-P`Matrix;
   I:=0; J:=0;
   for i in [1..n] do
    for j in [1..n] do
     if C[i][j] ne 0 then
      I:=i; J:=j;
      break i;
     end if;
    end for;
   end for;
   Append(~CriticalValues , (C[I][J])/(F1[I][J]) );
 
 
   iso:=false;
   jjj := Position(perfectlist,P);
   for i in [1..#perfectlist] do
    bool,trans:=TestIsometry(Pcont,perfectlist[i]:SL:=SL,CheckMembership:=CheckMembership);  
    if bool then
     iso:=true;
     Include(~E,<jjj,i>);
     if jjj  le i then Append(~fneu,1); else Append(~fneu,0); end if;
     Append(~Neighbours,i);
     break;
    end if;
   end for;
   if not iso then
    Append(~perfectlist,Pcont);
    Append(~minvecss,MinimalVectors(Pcont));
    Append(~fneu,1);
    Append(~Todo,Pcont);
    Append(~TrafoList,MatrixRing(Integers(),2*n)!1);
    Include(~E,<Position(perfectlist,P),Position(perfectlist,Pcont)>);
    Append(~Neighbours,#perfectlist);
   else
    Append(~TrafoList,trans);
   end if;
  end while;
  Append(~faceneu,fneu);
  Append(~PerfectNeighbourList,PerfectNeighbours);
  Append(~CriticalValueList,CriticalValues);
  Append(~FaceTrafoList,matbas(TrafoList));
  Append(~NeighbourList,Neighbours);
 end while;

 //Create a generating set of GL(L) as Z-matrices
 X:=[];
 for p in perfectlist do
  X:=X cat [MatrixRing(Integers(),2*n)!x : x in Generators(HermitianAutomorphismGroup(p:SL:=SL,CheckMembership:=CheckMembership))];
 end for;
 
 MFL:=[];
 for a in FaceTrafoList do
  X cat:= matbas2(a);
  MFL cat:=matbas2(a);
 end for;
 ZGENS:=X; 
 OKGENS:=matbas(X);            //Z-generating system
 MFL:=matbas(MFL);    //OK-generating system
 MFL:=SetToSequence(SequenceToSet(MFL));
 MFL:=[x: x in MFL| x ne Parent(x)!1];
 
 W:=KSpace(FieldOfFractions(Integers(K)),n);
 LatticeGens:=[W.i: i in [1..n-1]] cat [x*W.n: x in Generators(p2)];
 
 
 V:=New(VData);
 V`Lattice:=Module(LatticeGens);
 V`n:=n;
 V`d:=d;
 V`PerfectList:=perfectlist;
 V`FacesList:=facelist;
 V`ZGens:=ZGENS;
 V`OKGens:=OKGENS;
 V`MultFreeList:=MFL;
 V`CriticalValueList:=CriticalValueList;
 V`FaceTrafoList:=FaceTrafoList;
 V`NeighbourList:=NeighbourList;
 V`PerfectNeighbourList:=PerfectNeighbourList;
 V`PerpendicularList:=facevectlist;
 //V`PerpendicularList:=FacetVectorList;
 V`faceneu:=faceneu;
 
 return V;
end intrinsic;
