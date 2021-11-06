classdef OptoSession
    properties
        Region
        Animal
    end
    
    methods
        function r = getRegion(obj)
            r = obj.Region;
        end
        
        function r = getAnimal(obj)
            r = obj.Animal;
        end
    end
end