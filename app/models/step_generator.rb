# == Schema Information
# Schema version: 20100709222530
#
# Table name: step_generators
#
#  id          :integer(4)      not null, primary key
#  subprotocol :string(255)
#  sub_order   :integer(4)
#  title       :string(255)
#  description :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class StepGenerator < ActiveRecord::Base

=begin
Replace 'bla bla' with actual data
'construct' - construct.name
'part' - part.bio_byte.name
'part_coords' - position of part within plate 
AND CETERAS!!
=end

  def get_title(args)
    subtitle = self.title
    unless args[:part]==nil
      subtitle=subtitle.gsub("'part'", args[:part].bio_byte.name)
    end
    unless args[:construct]==nil
      subtitle=subtitle.gsub("'construct'", args[:construct].name)
    end
    return subtitle
  end


  def get_description(args)
    subdescription = self.description
    unless args[:part]==nil
      subdescription=subdescription.gsub("'part'", args[:part].bio_byte.name)
    end
    unless args[:construct]==nil
      subdescription=subdescription.gsub("'construct'", args[:construct].name)
    end
    return subdescription
  end

#class method

  def StepGenerator.generate_steps(experiment)

    #kill previously generated steps #TODO THIS IS REALLY SLOW!!!
    experiment.steps.each do |step|
      step.destroy if step.autogenerated==true
    end

    #remember handwritten steps
    hand_steps = experiment.steps.all(:order => "step_order")

    #toss in some new steps


    part_steps = StepGenerator.find(:all, 
                        :conditions=>{:subprotocol => "part addition"},
                        :order=> "sub_order")

    prep_steps = StepGenerator.find(:all, 
                        :conditions=>{:subprotocol => "assembly prep"},
                        :order=> "sub_order")

    post_steps = StepGenerator.find(:all,
                        :conditions=>{:subprotocol => "assembly completion"},
                        :order=> "sub_order")

    


    index=1
    experiment.constructs.each do |construct|
    #before adding parts  
      
      #todo suborders
      prep_steps.each do |step_gen|
        steptitle = step_gen.get_title(:construct => construct)
        stepdescription = step_gen.get_description(:construct => construct)    
        ns = experiment.steps.create( :title => steptitle,
                           :description => stepdescription,
                           :step_order => index,
                           :autogenerated => true )
        ns.step_order = index #hack to work around mike's after_create code
        ns.save
        index += 1
      end
    #part dependant steps
      construct.parts.all( :order => "part_order" ).each do |part|
        part_steps.each do |step_gen|
          steptitle = step_gen.get_title(:construct => construct, :part => part)
          stepdescription = step_gen.get_description(:construct => construct, :part => part)
          ns = experiment.steps.create( :title => steptitle, 
                             :description => stepdescription, 
                             :step_order => index,
                             :autogenerated => true )
          ns.step_order = index  #hack to work around mike's after_create code
          ns.save
          index += 1
        end 
      end
    #after adding parts
      post_steps.each do |step_gen|
        steptitle = step_gen.get_title(:construct => construct)
        stepdescription = step_gen.get_description(:construct => construct)    
        ns = experiment.steps.create( :title => steptitle,
                           :description => stepdescription,
                           :step_order => index,
                           :autogenerated => true)
        ns.step_order = index  #hack to work around mike's after_create code
        ns.save
        index += 1
      end

    end

    #alter order of handwritten steps to tack onto end

    hand_steps.each do |step|
      puts index
      step.step_order = index
      step.save
      index +=1
    end
    

  end

end
